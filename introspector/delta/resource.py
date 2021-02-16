from introspector.aws.svc import ImportSpec
import logging
from typing import Any, Dict, Iterator, List, Set, Optional

from sqlalchemy import or_, inspect, and_
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session
from sqlalchemy.sql.elements import ClauseElement

from introspector.delta import json_diff
from introspector.delta.attrs import diff_attrs
from introspector.delta.types import Raw
from introspector.error import GFInternal
from introspector.mapper import MappedAttribute, MappedResource, Mapper
from introspector.models import (ImportJob, MappedURI, RawImport, Resource,
                                 ResourceAttribute, ResourceDelta,
                                 ResourceAttributeDelta, ResourceRelation,
                                 ResourceRelationAttribute,
                                 ResourceRelationAttributeDelta,
                                 ResourceRelationDelta, ResourceRaw)

_log = logging.getLogger(__name__)


def _dump_state(obj):
  state = inspect(obj)
  return f'\n\tPersistent: {state.persistent}\n\tTransient: {state.transient}'


def map_resource_relations(db: Session,
                           import_job: ImportJob,
                           path_prefix: str,
                           mapper: Mapper,
                           uri_fn,
                           resource_name: str = None) -> Set[int]:
  provider_account_id = import_job.provider_account_id
  imports: Iterator[RawImport] = db.query(RawImport).filter(
      RawImport.import_job_id == import_job.id,
      RawImport.path.like(f'{path_prefix}%'),
      RawImport.provider_account_id == import_job.provider_account_id)
  found_relations = set()
  for raw_import in imports:
    import_resource_name = resource_name \
      if resource_name is not None \
        else raw_import.resource_name
    relations = mapper.map_relations(raw_import.path,
                                     raw_import.raw_resources(),
                                     raw_import.context, raw_import.service,
                                     import_resource_name, uri_fn)
    _log.debug(f'checking for map {raw_import.path}, {import_resource_name}')
    for parent_uri_spec, relation_type, target_uri_spec, attrs in relations:
      # TODO: pull out this
      _log.info(f'{parent_uri_spec} {relation_type} {target_uri_spec}')
      parent = Resource.get_by_uri(db, parent_uri_spec, provider_account_id)
      # TODO: accumulate errors on import into an import report
      if parent is None:
        _log.warn(
            f'Missing parent for relation {parent_uri_spec} {relation_type} {target_uri_spec} ({provider_account_id})'
        )
        continue
      parent_uri = parent.uri
      target = Resource.get_by_uri(db, target_uri_spec, provider_account_id)
      if target is None:
        _log.warn(
            f'Missing target for relation {parent_uri} {relation_type} [{target_uri_spec}] ({provider_account_id})'
        )
        continue
      target_uri = target.uri
      relation = ResourceRelation(
          resource_id=parent.id,
          target_id=target.id,
          relation=relation_type,
          raw={
              'resource': parent_uri,
              'target': target_uri,
              'relation': relation_type,
              'attributes': attrs
          },
          provider_account_id=import_job.provider_account_id)
      relation_attrs = [
          ResourceRelationAttribute(
              relation=relation,
              name=attr['name'],
              value=attr['value'],
              provider_account_id=import_job.provider_account_id)
          for attr in attrs
      ]
      found = _apply_relation(db, import_job, relation, parent_uri, target_uri,
                              relation_attrs)
      found_relations.add(found)
  return found_relations


def map_relation_deletes(db: Session, import_job: ImportJob, path_prefix: str,
                         found_relations: Set[int], spec: ImportSpec):
  deletes = db.query(ResourceRelation).filter(
      ~ResourceRelation.id.in_(found_relations), ).join(
          ResourceRelation.resource, aliased=True).filter(
              Resource.provider_account_id == import_job.provider_account_id,
              Resource.path.like(f'{path_prefix}%'))
  if spec is not None:
    clauses: List[ClauseElement] = []
    for service, resources in spec.items():
      if len(resources) == 0:
        clauses.append(Resource.service == service)
      else:
        clauses.append(
            and_(Resource.service == service,
                 Resource.provider_type.in_(tuple(resources))))
    deletes = deletes.filter(or_(*clauses))
  for deleted in deletes:
    _log.info(f'Deleting relation {deleted.id}')
    parent = db.query(Resource).get(deleted.resource_id)
    parent_uri = parent.uri
    target = db.query(Resource).get(deleted.target_id)
    target_uri = target.uri
    _delete_relation(db, import_job, deleted, parent_uri, target_uri)


def _delete_relation(db: Session, import_job: ImportJob,
                     deleted: ResourceRelation, parent_uri: str,
                     target_uri: str):
  delta = ResourceRelationDelta(
      import_job=import_job,
      provider_account_id=import_job.provider_account_id,
      resource_relation_id=deleted.id,
      change_type='delete',
      change_details={
          'relation': deleted.relation,
          'resource': parent_uri,
          'target': target_uri,
          'raw': deleted.raw
      })
  db.add(delta)
  for existing_attr in deleted.attributes:
    attr_delta = ResourceRelationAttributeDelta(
        provider_account_id=import_job.provider_account_id,
        resource_relation_delta=delta,
        resource_relation_attribute_id=existing_attr.id,
        change_type='delete',
        change_details={
            'name': existing_attr.name,
            'value': existing_attr.value
        })
    db.add(attr_delta)
    # Don't need to explicitly delete here, deletes will
    # cascade when we delete the relation
    #db.delete(existing_attr)
  _log.info(f'deleted {deleted}')
  db.delete(deleted)


def _apply_relation(db: Session, import_job: ImportJob,
                    relation: ResourceRelation, parent_uri: str,
                    target_uri: str,
                    relation_attrs: List[ResourceRelationAttribute]) -> int:
  previous_query = db.query(ResourceRelation).filter(
      ResourceRelation.relation == relation.relation,
      ResourceRelation.provider_account_id ==
      import_job.provider_account_id).join(
          ResourceRelation.resource,
          aliased=True).filter(Resource.uri == parent_uri).join(
              ResourceRelation.target,
              aliased=True).filter(Resource.uri == target_uri)
  previous = previous_query.one_or_none()
  if previous is None:
    db.add(relation)
    for attr in relation_attrs:
      db.add(attr)
    # need the id of relation we're adding
    db.flush()
    delta = ResourceRelationDelta(
        import_job=import_job,
        provider_account_id=import_job.provider_account_id,
        resource_relation_id=relation.id,
        change_type='add',
        change_details={
            'relation':
            relation.relation,
            'resource':
            parent_uri,
            'target':
            target_uri,
            'attributes': [{
                'name': attr.name,
                'value': attr.value
            } for attr in relation_attrs]
        })

    db.add(delta)
    for attr in relation_attrs:
      attr_delta = ResourceRelationAttributeDelta(
          provider_account_id=import_job.provider_account_id,
          resource_relation_delta=delta,
          resource_relation_attribute_id=attr.id,
          change_type='add',
          change_details={
              'name': attr.name,
              'value': attr.value
          })
      db.add(attr_delta)
    return relation.id
  else:
    stanzas = json_diff(previous.raw, relation.raw)
    if len(stanzas) == 0:
      _log.info(f'no change {relation}')
    else:
      _log.info('relation delta')
      delta = ResourceRelationDelta(
          import_job=import_job,
          provider_account_id=import_job.provider_account_id,
          resource_relation_id=previous.id,
          change_type='update',
          change_details={
              'relation':
              relation.relation,
              'resource':
              parent_uri,
              'target':
              target_uri,
              'attributes': [{
                  'name': attr.name,
                  'value': attr.value
              } for attr in db.query(ResourceRelationAttribute).filter(
                  ResourceRelationAttribute.relation_id == previous.id)]
          })
      db.add(delta)
      existing_attributes: Set[ResourceRelationAttribute] = set(
          previous.attributes)
      for attr in relation_attrs:
        existing_attr = _find_existing_relation_attr(existing_attributes, attr)
        if existing_attr is None:
          _log.info(f'new attr? {attr}')
          attr_delta = ResourceRelationAttributeDelta(
              provider_account_id=import_job.provider_account_id,
              resource_relation_delta=delta,
              resource_relation_attribute=attr,
              change_type='add',
              change_details={
                  'name': attr.name,
                  'value': attr.value
              })
          db.add(attr_delta)
        else:
          value_delta = json_diff(existing_attr.value, attr.value)
          if len(value_delta) != 0:
            _log.info(f'updated attr {attr.name}, {value_delta}')
            old_value = existing_attr.value
            existing_attr.value = attr.value
            db.add(existing_attr)
            db.flush()
            attr_delta = ResourceRelationAttributeDelta(
                provider_account_id=import_job.provider_account_id,
                resource_relation_delta=delta,
                resource_relation_attribute_id=existing_attr.id,
                change_type='update',
                change_details={
                    'name': existing_attr.name,
                    'old_value': old_value,
                    'new_value': attr.value,
                    'delta': value_delta
                })
            db.add(attr_delta)
          else:
            # No change, ignore
            pass
          # No longer eligible for matching
          existing_attributes.remove(existing_attr)
      for existing_attr in existing_attributes:
        db.delete(existing_attr)
        attr_delta = ResourceRelationAttributeDelta(
            provider_account_id=import_job.provider_account_id,
            resource_relation_delta=delta,
            resource_relation_attribute_id=existing_attr.id,
            change_type='delete',
            change_details={
                'name': existing_attr.name,
                'value': existing_attr.value
            })
      previous.raw = relation.raw
      db.add(previous)
    return previous.id


def _find_existing_relation_attr(
    attrs: Set[ResourceRelationAttribute], new_attr: ResourceRelationAttribute
) -> Optional[ResourceRelationAttribute]:
  for attr in attrs:
    if attr.name == new_attr.name:
      return attr
  return None


# TODO: consider a summary return value
def map_resource_prefix(db: Session,
                        import_job: ImportJob,
                        path_prefix: str,
                        mapper: Mapper,
                        uri_fn,
                        resource_name: str = None):
  _log.info(f'Mapping base - prefix {path_prefix}')
  source = 'base'
  imports: Iterator[RawImport] = db.query(RawImport).filter(
      RawImport.import_job_id == import_job.id,
      RawImport.path.like(f'{path_prefix}%'), RawImport.mapped == False,
      RawImport.source == source,
      RawImport.provider_account_id == import_job.provider_account_id)
  for raw_import in imports:
    import_resource_name = resource_name \
      if resource_name is not None \
        else raw_import.resource_name
    for mapped, attrs in mapper.map_resources(raw_import.raw_resources(),
                                              raw_import.context or {},
                                              raw_import.service,
                                              import_resource_name, uri_fn):
      apply_mapped_attrs(db,
                         import_job,
                         raw_import.path,
                         mapped,
                         attrs,
                         source,
                         raw_import_id=raw_import.id)
    raw_import.mapped = True
    db.add(raw_import)


def apply_mapped_attrs(db: Session, import_job: ImportJob, path: str,
                       mapped: MappedResource, attrs: List[MappedAttribute],
                       source: str, raw_import_id: Optional[int]):
  resource = Resource(provider_account_id=import_job.provider_account_id,
                      name=mapped.name,
                      path=path,
                      category=mapped.category,
                      provider_type=mapped.provider_type,
                      uri=mapped.uri,
                      service=mapped.service)
  # TODO: possibly a big perf hit?
  # Consider using a different API
  if resource.uri is None:
    raise GFInternal(f'Missing uri {mapped}')
  db.merge(
      MappedURI(uri=resource.uri,
                source=source,
                import_job_id=import_job.id,
                provider_account_id=import_job.provider_account_id,
                raw_import_id=raw_import_id))
  apply_resource(db, import_job, source, resource, mapped.raw, attrs)


def map_resource_deletes(db: Session, path_prefix: str, import_job: ImportJob,
                         spec: ImportSpec):
  # TODO: rewrite this into one query
  uris = db.query(MappedURI.uri).filter(
      MappedURI.import_job_id == import_job.id, MappedURI.source == 'base',
      MappedURI.provider_account_id == import_job.provider_account_id)
  deletes = db.query(Resource).filter(
      Resource.provider_account_id == import_job.provider_account_id,
      ~Resource.uri.in_(uris),
      # Handle the case the prefix is the whole path by including
      # exact match
      or_(Resource.path.like(f'{path_prefix}$%'),
          Resource.path == path_prefix))
  if spec is not None:
    clauses: List[ClauseElement] = []
    for service, resources in spec.items():
      if len(resources) == 0:
        clauses.append(Resource.service == service)
      else:
        clauses.append(
            and_(Resource.service == service,
                 Resource.provider_type.in_(tuple(resources))))
    #deletes = deletes.filter(Resource.service == service)
    deletes = deletes.filter(or_(*clauses))
  for deleted in deletes:
    # TODO: relation deletes
    raws: List[ResourceRaw] = db.query(ResourceRaw).filter(
        ResourceRaw.resource_id == deleted.id).all()
    raw = {raw.source: raw.raw for raw in raws}
    delta = ResourceDelta(provider_account_id=import_job.provider_account_id,
                          import_job=import_job,
                          resource_id=deleted.id,
                          change_type='delete',
                          change_details={
                              'path': deleted.path,
                              'uri': deleted.uri,
                              'name': deleted.name,
                              'raw': raw
                          })
    db.add(delta)
    for existing_attr in deleted.attributes:
      attr_delta = ResourceAttributeDelta(
          provider_account_id=import_job.provider_account_id,
          resource_delta=delta,
          # Should we include this?
          resource_attribute_id=existing_attr.id,
          change_type='delete',
          change_details={
              'type': existing_attr.attr_type,
              'name': existing_attr.name,
              'value': existing_attr.value
          })
      db.add(attr_delta)
      # Don't need to explicitly delete here, deletes will
      # cascade when we delete the resource
      #db.delete(existing_attr)
    for raw in raws:
      db.delete(raw)
    deleted_relations = db.query(ResourceRelation).filter(
        or_(ResourceRelation.target_id == deleted.id,
            ResourceRelation.resource_id == deleted.id))
    for relation in deleted_relations:
      if relation.target_id == deleted.id:
        target_uri = deleted.uri
        parent_uri = db.query(Resource).get(relation.resource_id).uri
      else:
        parent_uri = deleted.uri
        target_uri = db.query(Resource).get(relation.target_id).uri
      _delete_relation(db, import_job, relation, parent_uri, target_uri)
    db.delete(deleted)
    db.flush()
    _log.info(f'delete resource {deleted.uri}')


def apply_resource(db: Session, import_job: ImportJob, source: str,
                   resource: Resource, raw: Raw, attrs: List[MappedAttribute]):
  previous: Optional[ResourceRaw] = db.query(ResourceRaw).filter(
      ResourceRaw.source == source).join(
          Resource, Resource.id == ResourceRaw.resource_id,
          aliased=True).filter(
              Resource.uri == resource.uri, Resource.provider_account_id ==
              import_job.provider_account_id).one_or_none()
  if previous is None:
    _log.info(f'path %s, uri %s', resource.path, resource.uri)
    db.add(resource)
    db.flush()
    db.add(
        ResourceRaw(resource_id=resource.id,
                    source=source,
                    raw=raw,
                    provider_account_id=import_job.provider_account_id))
    delta = ResourceDelta(import_job=import_job,
                          resource_id=resource.id,
                          change_type='add',
                          change_details=raw,
                          provider_account_id=import_job.provider_account_id)
    db.add(delta)
    for attr in attrs:

      resource_attr = ResourceAttribute(
          resource=resource,
          source=source,
          attr_type=attr.type,
          name=attr.name,
          value=attr.value,
          provider_account_id=import_job.provider_account_id)
      db.add(resource_attr)
      db.flush()
      attr_delta = ResourceAttributeDelta(
          resource_delta=delta,
          resource_attribute_id=resource_attr.id,
          change_type='add',
          change_details=attr.as_dict(),
          provider_account_id=import_job.provider_account_id)
      db.add(attr_delta)
  else:
    resource_attrs = [
        ResourceAttribute(resource_id=previous.resource_id,
                          source=source,
                          attr_type=attr.type,
                          name=attr.name,
                          value=attr.value,
                          provider_account_id=import_job.provider_account_id)
        for attr in attrs
    ]
    if diff_attrs(db, previous.resource_id, source, import_job.id,
                  import_job.provider_account_id, resource.uri, previous.raw,
                  raw, resource_attrs):
      previous.raw = raw
      db.add(previous)
