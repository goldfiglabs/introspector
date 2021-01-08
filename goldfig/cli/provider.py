from functools import partial
from typing import Optional

from sqlalchemy.orm import Session

from goldfig.bootstrap_db import ReadOnlyProviderDB, scope_readonly_session
from goldfig.error import GFError


def provider_for_spec(db: Session, provider_spec: Optional[str]) -> int:
  '''
  Since tags are specific to a provider and required for CIS benchmarks,
  we require that you only run against a single provider.
  '''
  if provider_spec is None:
    # Get single provider
    ids = db.execute('SELECT id FROM provider_account').fetchall()
  else:
    # Get by account id?
    ids = db.execute('SELECT id FROM provider_account WHERE name = :name', {
        'name': provider_spec
    }).fetchall()
  if len(ids) == 0:
    raise GFError(
        'Provider not found. Check the account name or make sure it has been imported'
    )
  elif len(ids) > 1:
    msg = 'Multiple providers found, please specify a provider (--provider=)'
    raise GFError(msg)
  else:
    return ids[0][0]


def provider_scoped_db(provider_spec: Optional[str]) -> ReadOnlyProviderDB:
  return scope_readonly_session(
      partial(provider_for_spec, provider_spec=provider_spec))
