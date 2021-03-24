import logging
from typing import List, Set

from sqlalchemy.orm import Session

from introspector.delta import json_diff
from introspector.delta.types import Raw
from introspector.models import ResourceDelta, ResourceAttributeDelta, ResourceAttribute

_log = logging.getLogger(__name__)


def _find_existing_attr(attrs: Set[ResourceAttribute],
                        new_attr: ResourceAttribute):
  for attr in attrs:
    if attr.name == new_attr.name and \
        attr.attr_type == new_attr.attr_type:
      return attr
  return None


def diff_attrs(db: Session, resource_id: int, source: str, import_job_id: int,
               provider_account_id: int, uri: str, previous: Raw, current: Raw,
               attrs: List[ResourceAttribute]) -> bool:
  stanzas = json_diff(previous, current)
  if len(stanzas) == 0:
    _log.debug(f'no change {uri}')
    return False

  _log.debug(f'delta found for {uri}')
  delta = ResourceDelta(provider_account_id=provider_account_id,
                        import_job_id=import_job_id,
                        resource_id=resource_id,
                        change_type='update',
                        change_details=stanzas)
  db.add(delta)
  existing_attributes = set(
      db.query(ResourceAttribute).filter(
          ResourceAttribute.resource_id == resource_id,
          ResourceAttribute.source == source,
          ResourceAttribute.provider_account_id == provider_account_id))
  # existing_attributes = set(previous.attributes)
  for attr in attrs:
    existing_attr = _find_existing_attr(existing_attributes, attr)
    if existing_attr is None:
      _log.info(f'new attribute {attr}')
      # Otherwise it auto-inserts the new one.
      # Note to self: ORM bad
      attr.resource_id = resource_id
      db.add(attr)
      db.flush()
      attr_delta = ResourceAttributeDelta(
          provider_account_id=provider_account_id,
          resource_delta=delta,
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
            provider_account_id=provider_account_id,
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
        provider_account_id=provider_account_id,
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
  return True