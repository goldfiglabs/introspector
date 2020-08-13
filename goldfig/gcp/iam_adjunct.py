import logging
from typing import List

from sqlalchemy import text
from sqlalchemy.orm import Session

from goldfig import GLOBAL, ImportWriter
from goldfig.gcp.fetch import Proxy
from goldfig.models import ImportJob

_log = logging.getLogger(__name__)


def _find_global_roles(db: Session, provider_account_id: int) -> List[str]:
  stmt = text('''
    SELECT
        DISTINCT(Bindings.raw->'role') AS role
    FROM
      resource AS R
      INNER JOIN resource_raw AS RR
        ON R.id = RR.resource_id,
      LATERAL (SELECT jsonb_array_elements(RR.raw->'bindings') AS raw) AS Bindings
    WHERE
      R.provider_account_id = :provider_account_id
      AND R.category in ('Division', 'Organization')
  ''')
  results = db.execute(stmt, {'provider_account_id': provider_account_id})
  roles = []
  for row in results:
    roles.append(row['role'])
  return roles


def _import_roles(proxy: Proxy, writer: ImportWriter, roles: List[str]):
  iam = proxy.service('iam', 'v1')
  for role in roles:
    role_data = iam.get('roles', name=role)
    writer(GLOBAL, 'role', role_data)


def find_and_import_roles(db: Session, proxy: Proxy, writer: ImportWriter,
                          import_job: ImportJob) -> None:
  roles = _find_global_roles(db, import_job.provider_account_id)
  _log.info(f'Found global roles: {roles}')
  _import_roles(proxy, writer, roles)
