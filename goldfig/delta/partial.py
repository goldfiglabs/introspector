import logging
from typing import Any, Dict, Iterator, List, Optional

from sqlalchemy.orm import Session

from goldfig.delta.attrs import diff_attrs
from goldfig.delta.types import Raw
from goldfig.mapper import Mapper
from goldfig.models import (ImportJob, MappedURI, Resource, ResourceAttribute,
                            ResourceAttributeDelta, ResourceDelta, ResourceRaw,
                            RawImport)

_log = logging.getLogger(__name__)


def map_partial_prefix(db: Session, mapper: Mapper, import_job: ImportJob,
                       source: str, path_prefix: str, uri_fn):
  imports: Iterator[RawImport] = db.query(RawImport).filter(
      RawImport.import_job_id == import_job.id,
      RawImport.path.like(f'{path_prefix}%'), RawImport.mapped == False,
      RawImport.source == source)
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
                            attr_type=attr['type'],
                            name=attr['name'],
                            value=attr['value']) for attr in partial.attrs
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
    db.add(ResourceRaw(resource_id=target_id, source=source, raw=raw))
    for attr in attrs:
      db.add(attr)
    db.flush()  # need attribute ids below
    delta = ResourceDelta(import_job=import_job,
                          resource_id=target_id,
                          change_type='update',
                          change_details={
                              'source_added': source,
                              'raw': raw
                          })
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
    if diff_attrs(db, target_id, source, import_job.id, target_uri,
                  previous.raw, raw, attrs):
      previous.raw = raw
      db.add(previous)


def map_partial_deletes(db: Session,
                        import_job: ImportJob,
                        source: str,
                        service: Optional[str] = None):
  if service is None:
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
        AND R.service = :service
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
            'service': service,
            'source': source,
            'import_job_id': import_job.id,
            'provider_account_id': import_job.provider_account_id
        })
  for delete in deletes:
    uri = delete['uri']
    resource_id = delete['id']
    raw_id = delete['raw_id']
    delta = ResourceDelta(import_job=import_job,
                          resource_id=resource_id,
                          change_type='update',
                          change_details={'source_deleted': source})
    db.add(delta)
    db.query(ResourceRaw).filter(ResourceRaw.id == raw_id).delete()
    existing_attrs: Iterator[ResourceAttribute] = db.query(
        ResourceAttribute).filter(ResourceAttribute.resource_id == resource_id,
                                  ResourceAttribute.source == source)
    for attr in existing_attrs:
      attr_delta = ResourceAttributeDelta(resource_delta=delta,
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
