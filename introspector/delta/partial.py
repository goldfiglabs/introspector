from introspector.aws.svc import ImportSpec
import logging
from typing import Any, Dict, Iterator, List, Optional

from sqlalchemy.orm import Session

from introspector.delta.attrs import diff_attrs
from introspector.delta.types import Raw
from introspector.mapper import Mapper
from introspector.models import (ImportJob, MappedURI, Resource,
                                 ResourceAttribute, ResourceAttributeDelta,
                                 ResourceDelta, ResourceRaw, RawImport)

_log = logging.getLogger(__name__)


def map_partial_prefix(db: Session, mapper: Mapper, import_job: ImportJob,
                       source: str, path_prefix: str, uri_fn):
  imports = db.query(RawImport).filter(
      RawImport.import_job_id == import_job.id,
      RawImport.path.like(f'{path_prefix}%'), RawImport.mapped == False,
      RawImport.source == source,
      RawImport.provider_account_id == import_job.provider_account_id)
  for raw_import in imports:
    ctx: Dict[str, Any] = raw_import.context or {}
    ctx['source'] = source
    for partial in mapper.map_partials(raw_import.raw_resources(), ctx,
                                       raw_import.service, uri_fn,
                                       raw_import.resource_name):
      db.merge(
          MappedURI(uri=partial.target_uri,
                    source=source,
                    import_job_id=import_job.id,
                    provider_account_id=import_job.provider_account_id,
                    raw_import_id=raw_import.id))
      target: Optional[Resource] = db.query(Resource).filter(
          Resource.uri == partial.target_uri, Resource.provider_account_id ==
          import_job.provider_account_id).one_or_none()
      if target is None:
        _log.warn(f'Missing target for partial {partial.target_uri}')
        continue
      resource_attrs = [
          ResourceAttribute(resource_id=target.id,
                            source=source,
                            attr_type=attr.type,
                            name=attr.name,
                            value=attr.value,
                            provider_account_id=import_job.provider_account_id)
          for attr in partial.attrs
      ]
      apply_partial(db, import_job, source, partial.target_uri, target.id,
                    partial.raw, resource_attrs)


def apply_partial(db: Session, import_job: ImportJob, source: str,
                  target_uri: str, target_id: int, raw: Raw,
                  attrs: List[ResourceAttribute]):
  previous: Optional[ResourceRaw] = db.query(ResourceRaw).filter(
      ResourceRaw.source == source).join(
          Resource, Resource.id == ResourceRaw.resource_id,
          aliased=True).filter(
              Resource.uri == target_uri, Resource.provider_account_id ==
              import_job.provider_account_id).one_or_none()
  if previous is None:
    # first import for this partial
    _log.info(f'Partial from {source} added to {target_uri}')
    db.add(
        ResourceRaw(resource_id=target_id,
                    source=source,
                    raw=raw,
                    provider_account_id=import_job.provider_account_id))
    for attr in attrs:
      db.add(attr)
    db.flush()  # need attribute ids below
    delta = ResourceDelta(import_job=import_job,
                          resource_id=target_id,
                          change_type='update',
                          change_details={
                              'source_added': source,
                              'raw': raw
                          },
                          provider_account_id=import_job.provider_account_id)
    db.add(delta)
    for attr in attrs:
      attr_delta = ResourceAttributeDelta(
          resource_delta=delta,
          resource_attribute_id=attr.id,
          change_type='add',
          change_details={
              'type': attr.attr_type,
              'name': attr.name,
              'value': attr.value
          },
          provider_account_id=import_job.provider_account_id)
      db.add(attr_delta)
  else:
    if diff_attrs(db, target_id, source, import_job.id,
                  import_job.provider_account_id, target_uri, previous.raw,
                  raw, attrs):
      previous.raw = raw
      db.add(previous)


def map_partial_deletes(db: Session, import_job: ImportJob, source: str,
                        spec: ImportSpec):
  if spec is None:
    deletes = db.execute(
        '''
      SELECT
        R.id,
        R.uri,
        Raw.id AS raw_id
      FROM
        resource AS R
        INNER JOIN resource_raw AS Raw
          ON Raw.resource_id = R.id
          AND Raw.source = :source
      WHERE
        R.provider_account_id = :provider_account_id
        AND R.uri NOT IN (
          SELECT
            uri
          FROM
            mapped_uri
          WHERE
            source = :source
            AND import_job_id = :import_job_id
        )
    ''', {
            'source': source,
            'import_job_id': import_job.id,
            'provider_account_id': import_job.provider_account_id
        })
  else:
    clauses = []
    i = 0
    params = {}
    for service, resources in spec.items():
      service_param = f'service_{i}'
      i += 1
      params[service_param] = service
      if len(resources) == 0:
        clauses.append(f'R.service = :{service_param}')
      else:
        types = []
        for resource_type in resources:
          resource_param = f'resource_{i}'
          i += 1
          params[resource_param] = resource_type
          types.append(resource_param)
        type_string = ', '.join(map(lambda s: ':' + s, types))
        clauses.append(f'R.service = :{service_param} AND R.provider_type IN ({type_string})')
    restrictions = '(' + ' OR '.join(map(lambda clause: f'({clause})', clauses)) + ')'
    params.update({
      'source': source,
      'import_job_id': import_job.id,
      'provider_account_id': import_job.provider_account_id
    })
    deletes = db.execute(
        f'''
      SELECT
        R.id,
        R.uri,
        Raw.id AS raw_id
      FROM
        resource AS R
        INNER JOIN resource_raw AS Raw
          ON Raw.resource_id = R.id
          AND Raw.source = :source
      WHERE
        R.provider_account_id = :provider_account_id
        AND {restrictions}
        AND R.uri NOT IN (
          SELECT
            uri
          FROM
            mapped_uri
          WHERE
            source = :source
            AND import_job_id = :import_job_id
        )
    ''', params)
  for delete in deletes:
    uri = delete['uri']
    resource_id = delete['id']
    raw_id = delete['raw_id']
    delta = ResourceDelta(provider_account_id=import_job.provider_account_id,
                          import_job=import_job,
                          resource_id=resource_id,
                          change_type='update',
                          change_details={'source_deleted': source})
    db.add(delta)
    db.query(ResourceRaw).filter(ResourceRaw.id == raw_id).delete()
    existing_attrs = db.query(
        ResourceAttribute).filter(
            ResourceAttribute.resource_id == resource_id,
            ResourceAttribute.source == source,
            ResourceAttribute.provider_account_id ==
            import_job.provider_account_id)
    for attr in existing_attrs:
      attr_delta = ResourceAttributeDelta(
          provider_account_id=import_job.provider_account_id,
          resource_delta=delta,
          resource_attribute_id=attr.id,
          change_type='delete',
          change_details={
              'type': attr.attr_type,
              'name': attr.name,
              'value': attr.value
          })
      db.add(attr_delta)
      db.delete(attr)
    _log.info(f'Delete source {source} for {uri}')
