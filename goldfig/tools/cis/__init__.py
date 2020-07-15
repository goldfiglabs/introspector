from typing import List, Optional

from sqlalchemy.orm import Session

from goldfig.error import GFError
from goldfig.models import ProviderAccount
from goldfig.tools.cis.data_protection import (DiskEncrypted, PublicImage,
                                                  HttpsEndpoints)
from goldfig.tools.cis.identity import IamProfiles

ALL_BENCHMARKS = [DiskEncrypted, PublicImage, HttpsEndpoints, IamProfiles]


def provider_for_spec(db: Session,
                      provider_spec: Optional[str]) -> ProviderAccount:
  '''
  Since tags are specific to a provider and required for CIS benchmarks,
  we require that you only run against a single provider.
  '''
  if provider_spec is None:
    # Get single provider
    providers = db.query(ProviderAccount).all()
  else:
    # Get by provider type
    if provider_spec in ('gcp', 'aws'):
      providers = db.query(ProviderAccount).filter(
          ProviderAccount.provider == provider_spec).all()
    else:
      # Get by account id?
      providers = db.query(ProviderAccount).filter(
          ProviderAccount.name == provider_spec).all()
  if len(providers) > 1:
    providers_str = '\n'.join(
        [f'{provider.name} - {provider.provider}' for provider in providers])
    msg = 'Multiple providers found, please specify a provider (--provider=):\n' + providers_str
    raise GFError(msg)
  else:
    return providers[0]
