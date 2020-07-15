from typing import List

from sqlalchemy.orm import Session


# TODO: further filter support
def find_untagged(db: Session, provider_account_id: int) -> List[str]:
  result = db.execute(
      '''
    SELECT
      R.uri AS uri
    FROM
      resource_attribute AS Tags
      LEFT JOIN resource AS R
        ON Tags.resource_id = R.id
    WHERE
      Tags.type = 'Metadata'
      AND Tags.attr_name = 'Tags'
      AND Tags.attr_value = '{}'::jsonb
      AND R.provider_account_id = :provider_account_id
  ''', {'provider_account_id': provider_account_id})
  return list(map(lambda row: row['uri'], result))


def tag_report(db: Session, provider_account_id: int):
  result = db.execute(
      '''
    SELECT
      KV.key AS key,
      ARRAY_AGG(DISTINCT KV.value#>> '{}') AS values
    FROM
      resource_attribute AS Tags
      CROSS JOIN LATERAL jsonb_each(Tags.attr_value) AS KV
      LEFT JOIN resource AS R
        ON R.id = Tags.resource_id
    WHERE
      Tags.type = 'Metadata'
      AND Tags.attr_name = 'Tags'
      AND R.provider_account_id = :provider_account_id
    GROUP BY KV.key
  ''', {'provider_account_id': provider_account_id})
  return {row['key']: row['values'] for row in result}
