from dataclasses import dataclass
from datetime import datetime
from typing import List, Optional

from sqlalchemy.orm import Session

from introspector.error import GFInternal
from introspector.models import ImportJob


@dataclass
class Report:
  resources_added: int
  resources_updated: int
  resources_deleted: int
  attrs_added: int
  attrs_updated: int
  attrs_deleted: int
  start: datetime
  end: Optional[datetime]
  errors: Optional[List[str]]


def report_for_import(db: Session, import_job: ImportJob) -> Report:
  # TODO: import status
  counts = db.execute(
      '''
    SELECT
      change_type,
      COUNT(*) AS cnt
    FROM
      resource_delta
    WHERE
      import_job_id = :import_job_id
    GROUP BY
      change_type
  ''', {'import_job_id': import_job.id})
  resources_added = 0
  resources_updated = 0
  resources_deleted = 0
  for row in counts:
    change_type = row['change_type']
    count = row['cnt']
    if change_type == 'add':
      resources_added = count
    elif change_type == 'update':
      resources_updated = count
    elif change_type == 'delete':
      resources_deleted = count
    else:
      raise GFInternal(f'Unknown resource_delta.change_type {change_type}')
  attr_counts = db.execute(
      '''
    SELECT
      RAD.change_type,
      COUNT(*) AS cnt
    FROM
      resource_attribute_delta AS RAD
      LEFT JOIN resource_delta AS RD
        ON RD.id = RAD.resource_delta_id
    WHERE
      RD.change_type = 'update'
      AND RD.import_job_id = :import_job_id
    GROUP BY
      RAD.change_type
  ''', {'import_job_id': import_job.id})
  attrs_added = 0
  attrs_updated = 0
  attrs_deleted = 0
  for row in attr_counts:
    change_type = row['change_type']
    count = row['cnt']
    if change_type == 'add':
      attrs_added = count
    elif change_type == 'update':
      attrs_updated = count
    elif change_type == 'delete':
      attrs_deleted = count
    else:
      raise GFInternal(
          f'Unknown resource_attribute_delta.change_type {change_type}')
  return Report(resources_added=resources_added,
                resources_updated=resources_updated,
                resources_deleted=resources_deleted,
                attrs_added=attrs_added,
                attrs_updated=attrs_updated,
                attrs_deleted=attrs_deleted,
                start=import_job.start_date,
                end=import_job.end_date,
                errors=import_job.error_details)
