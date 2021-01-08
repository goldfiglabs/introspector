from dataclasses import dataclass
from typing import Dict, List, Optional

import click
from sqlalchemy.orm import Session

from goldfig.bootstrap_db import readonly_session, provider_tables, scoped_readonly_session
from goldfig.cli.util import print_report
from goldfig.delta.report import report_for_import
from goldfig.models import ImportJob, ProviderAccount

ResourceCount = Dict[str, int]


@dataclass
class Status:
  provider: ResourceCount
  common: ResourceCount
  raw: ResourceCount


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


def _status(db: Session, provider: ProviderAccount) -> Status:
  # views = view_names()
  # provider_views = filter(lambda view: view.startswith(provider.provider),
  #                         views)
  tables = provider_tables(db, provider.provider)
  provider_results = {}
  for table in tables:
    result = db.execute('SELECT COUNT(*) FROM ' + table)
    provider_results[table] = result.scalar()

  common_views = provider_tables(db, 'common')
  common_results = {}
  for common_view in common_views:
    result = db.execute('SELECT COUNT(*) FROM ' + common_view)
    common_results[common_view] = result.scalar()

  raw_results = {}
  resource_count = db.execute(
      'SELECT COUNT(*) FROM resource WHERE provider_account_id = :provider_account_id',
      {
          'provider_account_id': provider.id
      }).scalar()
  raw_results['resources'] = resource_count
  attr_count = db.execute(
      '''
    SELECT
      COUNT(*)
    FROM
      resource AS R
      LEFT JOIN resource_attribute AS RA
        ON RA.resource_id = R.id
    WHERE
      R.provider_account_id = :provider_account_id
  ''', {
          'provider_account_id': provider.id
      }).scalar()
  raw_results['attribrutes'] = attr_count
  return Status(provider=provider_results,
                common=common_results,
                raw=raw_results)


def print_status(db: Session, provider: ProviderAccount):
  status = _status(db, provider)
  print(f'{provider.provider} - {provider.name}')
  print('Provider Resources')
  for view, count in status.provider.items():
    print(f'  {view}:  {count}')
  print('Common Resources')
  for view, count in status.common.items():
    print(f'  {view}:  {count}')
  print('Raw Resources')
  for view, count in status.raw.items():
    print(f'  {view}:  {count}')

  latest_import = ImportJob.latest(db, provider.id)
  if latest_import is None:
    # TODO: print command to run an import
    print('No imports found.')
  else:
    import_report = report_for_import(db, latest_import)
    print('Latest import')
    print_report(import_report)
  print('\n')


@click.command('status',
               help='Show a summary of the resources currently imported')
@click.option(
    '-p',
    '--provider',
    'provider_spec',
    type=str,
    help=
    'Either a provider type (gcp, aws) or account id to restrict the resources scanned. Default is to scan all accounts'
)
def cmd(provider_spec: Optional[str]):
  db = readonly_session()
  providers = _provider_for_spec(db, provider_spec)
  if len(providers) > 0:
    for provider in providers:
      scoped_db = scoped_readonly_session(provider.id)
      print_status(scoped_db, provider)
      scoped_db.close()
  elif provider_spec is None:
    print('No accounts are currently imported')
  else:
    print('No matching accounts are currently imported')
