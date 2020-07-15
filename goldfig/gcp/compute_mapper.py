from typing import Set

from sqlalchemy import text
from sqlalchemy.orm import Session

from goldfig.models import ResourceRelation


def add_image_attachments(db: Session, provider_account_id: int) -> Set[int]:
  stmt = text('''
  -- mappings is all of the relations that should exist
  WITH mappings AS (SELECT
    VM.id AS vm_id,
    VM.uri AS vm_uri,
    Image.id AS image_id
  FROM
    resource AS VM,
    resource_relation AS Attached,
    resource AS Disk,
    resource_relation AS Imaged,
    resource AS Image
  WHERE
    VM.provider_account_id = :provider_account_id
    AND VM.provider_type = 'instance'
    AND Attached.resource_id = VM.id
    AND Attached.relation = 'attached'
    -- attached disk
    AND Disk.provider_type = 'disk'
    AND Attached.target_id = Disk.id
    AND Imaged.resource_id = Disk.id
    AND Imaged.relation = 'imaged'
    -- imaged Image
    AND Image.provider_type = 'image'
    AND Imaged.target_id = Image.id
  )
  SELECT
    M.vm_id,
    M.image_id,
    VM_Imaged.id AS existing
  FROM
    -- outer join against the mappings that actually exist
    -- this will give us null for the missing ones, or access to the id
    -- for the existing ones
    mappings AS M
    LEFT OUTER JOIN resource_relation AS VM_Imaged
      ON VM_Imaged.resource_id = M.vm_id
      AND VM_Imaged.relation = 'imaged'
      AND VM_Imaged.target_id = M.image_id
  ''')
  results = db.execute(stmt, {'provider_account_id': provider_account_id})
  found_relations: Set[int] = set()
  for result in results:
    existing = result['existing']
    if existing is not None:
      found_relations.add(existing)
    else:
      relation = ResourceRelation(resource_id=result['vm_id'],
                                  relation='imaged',
                                  target_id=result['image_id'])
      db.add(relation)
      db.flush()
      found_relations.add(relation.id)

  return found_relations
