from typing import List, Optional

import click
from sqlalchemy.orm import Session

from goldfig.bootstrap_db import readonly_session
from goldfig.error import GFError
from goldfig.models import ProviderAccount
from goldfig.tools.tags import find_untagged, tag_report


@click.group('tags', help='Tools for working with tagged resources')
def cmd():
  pass


def _provider_for_spec(db: Session,
                       provider_spec: Optional[str]) -> List[ProviderAccount]:
  if provider_spec is None:
    # Get single provider
    providers = db.query(ProviderAccount).all()
  else:
    # Get by provider type
    if provider_spec in ('gcp', 'aws'):
      providers = list(
          db.query(ProviderAccount).filter(
              ProviderAccount.provider == provider_spec))
    else:
      # Get by account id?
      providers = list(
          db.query(ProviderAccount).filter(
              ProviderAccount.name == provider_spec))
  return providers


@cmd.command('find-untagged', help='A tool to find resources missing tags')
@click.option(
    '-p',
    '--provider',
    'provider_spec',
    type=str,
    default=None,
    help=
    'Either a provider type (gcp, aws) or account id to restrict the resources scanned. Default is to scan all accounts'
)
def find_untagged_cmd(provider_spec: Optional[str]):
  db = readonly_session()
  providers = _provider_for_spec(db, provider_spec)
  if len(providers) == 0:
    raise GFError(f'No providers found matching "{provider_spec}"')
  for provider in providers:
    print(
        f'Untagged resources for {provider.provider} account {provider.name}')
    uris = find_untagged(db, provider.id)
    if len(uris) > 0:
      print('\t' + '\n\t'.join(uris))
    else:
      print('\tNONE')


def _sanitize(s: str) -> str:
  escaped = s.replace('\n', '\\n').replace('\t', '\\t')
  if len(escaped) > 30:
    return escaped[:27] + '...'
  else:
    return escaped


@cmd.command('report', help='A tool to help understand the usage of tags')
@click.option(
    '-p',
    '--provider',
    'provider_spec',
    type=str,
    default=None,
    help=
    'Either a provider type (gcp, aws) or account id to restrict the resources scanned. Default is to scan all accounts'
)
def report_tags_cmd(provider_spec: Optional[str]):
  db = readonly_session()
  providers = _provider_for_spec(db, provider_spec)
  if len(providers) == 0:
    raise GFError(f'No providers found matching "{provider_spec}"')
  for provider in providers:
    report = tag_report(db, provider.id)
    print(f'Tags in {provider.provider} account {provider.name}')
    if len(report) == 0:
      print('NONE')
    else:
      for key, values in report.items():
        sanitized = [_sanitize(s) for s in values]
        print(f'({len(sanitized)}) ' + key.ljust(30) + ',  '.join(sanitized))
