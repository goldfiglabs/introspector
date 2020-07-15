import logging
from typing import Dict, List, Set, Optional

from sqlalchemy import or_, inspect
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from goldfig.delta import json_diff
from goldfig.error import GFInternal
from goldfig.mapper import Mapper
from goldfig.models import (ImportJob, MappedURI, RawImport, Resource,
                               ResourceAttribute, ResourceDelta,
                               ResourceAttributeDelta, ResourceRelation,
                               ResourceRelationAttribute,
                               ResourceRelationAttributeDelta,
                               ResourceRelationDelta)

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
  imports = db.query(RawImport).filter(
      RawImport.import_job_id == import_job.id,
      or_(RawImport.path.like(f'{path_prefix}%'),
          RawImport.path == path_prefix))
  found_relations = set()
  for raw_import in imports:
    import_resource_name = resource_name \
      if resource_name is not None \
        else raw_import.resource_name
    relations = mapper.map_relations(raw_import.path,
                                     raw_import.raw_resources(),
                                     import_resource_name, uri_fn)
    _log.debug(f'checking for map {raw_import.path}, {import_resource_name}')
    for parent_uri, relation_type, target_uri, attrs in relations:
      # TODO: pull out this
      _log.info(f'{parent_uri} {relation_type} {target_uri}')
      parent = Resource.get_by_uri(db, parent_uri, provider_account_id)
      # TODO: accumulate errors on import into an import report
      if parent is None:
        _log.warn(
            f'Missing parent for relation {parent_uri} {relation_type} {target_uri} ({provider_account_id})'
        )
        continue
      target = Resource.get_by_uri(db, target_uri, provider_account_id)
      if target is None:
        _log.warn(
            f'Missing target for relation {parent_uri} {relation_type} [{target_uri}] ({provider_account_id})'
        )
        continue
      relation = ResourceRelation(resource_id=parent.id,
                                  target_id=target.id,
                                  relation=relation_type,
                                  raw={
                                      'resource': parent_uri,
                                      'target': target_uri,
                                      'relation': relation_type,
                                      'attributes': attrs
                                  })
      relation_attrs = [
          ResourceRelationAttribute(relation=relation,
                                    name=attr['name'],
                                    value=attr['value']) for attr in attrs
      ]
      found = _apply_relation(db, import_job, relation, parent_uri, target_uri,
                              relation_attrs)
      found_relations.add(found)
  return found_relations


def map_relation_deletes(db: Session, import_job: ImportJob, path_prefix: str,
                         found_relations: Set[int]):
  deletes = db.query(ResourceRelation).filter(
      ~ResourceRelation.id.in_(found_relations), ).join(
          ResourceRelation.resource, aliased=True).filter(
              or_(Resource.path.like(f'{path_prefix}$%'),
                  Resource.path == path_prefix))
  for deleted in deletes:
    parent = db.query(Resource).get(deleted.resource_id)
    parent_uri = parent.uri
    target = db.query(Resource).get(deleted.target_id)
    target_uri = target.uri
    delta = ResourceRelationDelta(import_job=import_job,
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
      ResourceRelation.relation == relation.relation).join(
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
    delta = ResourceRelationDelta(import_job=import_job,
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
      existing_attributes = set(previous.attributes)
      for attr in relation_attrs:
        existing_attr = _find_existing_relation_attr(existing_attributes, attr)
        if existing_attr is None:
          _log.info(f'new attr? {attr}')
          attr_delta = ResourceRelationAttributeDelta(
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
  _log.info(f'Mapping prefix {path_prefix}')
  imports = db.query(RawImport).filter(
      RawImport.import_job_id == import_job.id,
      RawImport.path.like(f'{path_prefix}%'), RawImport.mapped == False)
  for raw_import in imports:
    import_resource_name = resource_name \
      if resource_name is not None \
        else raw_import.resource_name
    for mapped, attrs in mapper.map_resources(raw_import.raw_resources(),
                                              raw_import.context,
                                              import_resource_name, uri_fn):
      apply_mapped_attrs(db,
                         import_job,
                         raw_import.path,
                         mapped,
                         attrs,
                         raw_import_id=raw_import.id)
    raw_import.mapped = True
    db.add(raw_import)


def apply_mapped_attrs(db: Session, import_job: ImportJob, path: str,
                       mapped: Dict, attrs: List[Dict],
                       raw_import_id: Optional[int]):
  resource = Resource(provider_account_id=import_job.provider_account_id,
                      name=mapped['name'],
                      path=path,
                      category=mapped['category'],
                      provider_type=mapped['provider_type'],
                      raw=mapped['raw'],
                      uri=mapped['uri'],
                      service=mapped.get('service'))
  # TODO: possibly a big perf hit?
  # Consider using a different API
  db.merge(
      MappedURI(uri=resource.uri,
                import_job_id=import_job.id,
                raw_import_id=raw_import_id))
  resource_attrs = [
      ResourceAttribute(resource=resource,
                        attr_type=attr['type'],
                        name=attr['name'],
                        value=attr['value']) for attr in attrs
  ]
  apply_resource(db, import_job, resource, resource_attrs)


def map_resource_deletes(db: Session, path_prefix: str, import_job: ImportJob,
                         service: Optional[str]):
  uris = db.query(
      MappedURI.uri).filter(MappedURI.import_job_id == import_job.id)
  deletes = db.query(Resource).filter(
      Resource.provider_account_id == import_job.provider_account_id,
      ~Resource.uri.in_(uris),
      # Handle the case the prefix is the whole path by including
      # exact match
      or_(Resource.path.like(f'{path_prefix}$%'),
          Resource.path == path_prefix))
  if service is not None:
    deletes = deletes.filter(Resource.service == service)
  for deleted in deletes:
    # TODO: relation deletes
    delta = ResourceDelta(import_job=import_job,
                          resource_id=deleted.id,
                          change_type='delete',
                          change_details={
                              'path': deleted.path,
                              'uri': deleted.uri,
                              'name': deleted.name,
                              'raw': deleted.raw
                          })
    db.add(delta)
    for existing_attr in deleted.attributes:
      attr_delta = ResourceAttributeDelta(
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
    db.delete(deleted)
    _log.info(f'delete resource {deleted.uri}')


def apply_resource(db: Session, import_job: ImportJob, resource: Resource,
                   attrs: List[ResourceAttribute]):
  previous = db.query(Resource).filter(
      Resource.uri == resource.uri, Resource.provider_account_id ==
      import_job.provider_account_id).one_or_none()
  if previous is None:
    _log.info(f'path %s, uri %s', resource.path, resource.uri)
    db.add(resource)
    for attr in attrs:
      db.add(attr)
    # Need resource id
    try:
      db.flush()
    except IntegrityError as e:
      _log.debug(f'new {resource.path}')
      existing = db.query(Resource).filter(
          Resource.uri == resource.uri, Resource.provider_account_id ==
          import_job.provider_account_id).one_or_none()
      _log.debug(f'existing {existing.path}')
      raise e
    delta = ResourceDelta(import_job=import_job,
                          resource_id=resource.id,
                          change_type='add',
                          change_details=resource.raw)
    db.add(delta)
    for attr in attrs:
      attr_delta = ResourceAttributeDelta(resource_delta=delta,
                                          resource_attribute_id=attr.id,
                                          change_type='add',
                                          change_details={
                                              'type': attr.attr_type,
                                              'name': attr.name,
                                              'value': attr.value
                                          })
      db.add(attr_delta)
  else:
    stanzas = json_diff(previous.raw, resource.raw)
    if len(stanzas) == 0:
      _log.info(f'no change {resource.uri}')
      if previous.path != resource.path:
        raise GFInternal(
            f'path mismatch on existing resource. Old {previous.path} vs new {resource.path}'
        )
    else:
      _log.info(f'delta found for {resource.uri}')
      delta = ResourceDelta(import_job=import_job,
                            resource_id=previous.id,
                            change_type='update',
                            change_details=stanzas)
      db.add(delta)
      existing_attributes = set(previous.attributes)
      for attr in attrs:
        existing_attr = _find_existing_attr(existing_attributes, attr)
        if existing_attr is None:
          _log.info(f'new attribute {attr}')
          # Otherwise it auto-inserts the new one.
          # Note to self: ORM bad
          attr.resource = previous
          db.add(attr)
          db.flush()
          attr_delta = ResourceAttributeDelta(resource_delta=delta,
                                              resource_attribute_id=attr.id,
                                              change_type='add',
                                              change_details={
                                                  'type': attr.attr_type,
                                                  'name': attr.name,
                                                  'value': attr.value
                                              })
          db.add(attr_delta)
        else:
          value_delta = json_diff(existing_attr.value, attr.value)
          if len(value_delta) != 0:
            old_value = existing_attr.value
            existing_attr.value = attr.value
            db.add(existing_attr)
            attr_delta = ResourceAttributeDelta(
                resource_delta=delta,
                resource_attribute_id=existing_attr.id,
                change_type='update',
                change_details={
                    'type': existing_attr.attr_type,
                    'name': existing_attr.name,
                    'old_value': old_value,
                    'new_value': attr.value,
                    'delta': value_delta
                })
            db.add(attr_delta)
          else:
            # No change ignore
            pass
          # No longer eligible for matching
          # although this shouldn't be a problem unless we have
          # dupes in the future
          existing_attributes.remove(existing_attr)
      for existing_attr in existing_attributes:
        db.delete(existing_attr)
        attr_delta = ResourceAttributeDelta(
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
      previous.raw = resource.raw
      db.add(previous)


def _find_existing_attr(attrs: Set[ResourceAttribute],
                        new_attr: ResourceAttribute):
  for attr in attrs:
    if attr.name == new_attr.name and \
        attr.attr_type == new_attr.attr_type:
      return attr
  return None
