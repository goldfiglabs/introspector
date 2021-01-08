import logging
from typing import Dict, Optional

import click
from tabulate import tabulate

from goldfig.account import delete_account
from goldfig.aws import (build_aws_import_job, get_boto_session,
                         account_paths_for_import, get_boto_session)
from goldfig.aws.importer import run_single_session, run_parallel_session
from goldfig.aws.map import map_import
from goldfig.aws.region import RegionCache
from goldfig.bootstrap_db import import_session, refresh_views
from goldfig.cli.util import print_report, query_yes_no
from goldfig.delta.report import report_for_import
from goldfig.error import GFInternal
from goldfig.models import ProviderAccount, ImportJob

_log = logging.getLogger(__name__)


@click.group('aws', help='Tools for AWS accounts')
def cmd():
  pass


@cmd.command('import',
             help='Imports the assets from an AWS account into Gold Fig')
@click.option('-d',
              '--debug',
              'debug',
              is_flag=True,
              default=False,
              type=bool,
              hidden=True)
@click.option('-f',
              '--force',
              'force',
              default=False,
              is_flag=True,
              help='Skip prompts for adding accounts')
@click.option('-s',
              '--service',
              default=None,
              type=str,
              required=False,
              help='Only import the specified service')
@click.option('--dry-run', 'dry_run', default=False, hidden=True, is_flag=True)
def import_aws_cmd(debug: bool, force: bool, dry_run: bool,
                   service: Optional[str]):
  db = import_session()
  boto = get_boto_session()
  if force:
    confirm = lambda _: True
  else:

    def _confirm(identity: Dict) -> bool:
      return query_yes_no(
          f'Add AWS account {identity["Account"]} using identity {identity["Arn"]}?',
          default='yes')

    confirm = _confirm
  import_job = build_aws_import_job(db, boto, confirm)
  db.add(import_job)
  db.flush()
  region_cache = RegionCache(boto)
  if debug:
    run_single_session(db, import_job.id, region_cache, service)
    db.flush()
    map_import(db, import_job.id)
    refresh_views(db, import_job.provider_account_id)
    if not dry_run:
      db.commit()
    print('done', import_job.id)
  else:
    accounts = account_paths_for_import(db, import_job)
    db.commit()
    # No db required for parallel invocation
    exceptions = run_parallel_session(region_cache, accounts, import_job,
                                      service)
    # Make certain we're using the current db session
    import_job = db.query(ImportJob).get(import_job.id)
    if len(exceptions) == 0:
      db.commit()
      map_import(db, import_job.id, service)
      db.commit()
      refresh_views(db, import_job.provider_account_id)
      import_job.mark_complete(exceptions=[])
    else:
      import_job.mark_complete(exceptions)
    db.add(import_job)
    db.commit()
    report = report_for_import(db, import_job)
    print(f'Results - Import #{import_job.id}')
    print_report(report)


@cmd.command('remap', hidden=True)
@click.option(
    '-i',
    '--import_job',
    'import_job_id',
    help=
    'Remap a specific import. If not specified, the last import will be used',
    type=int,
    default=None)
@click.option('--dry-run', 'dry_run', default=False, hidden=True, is_flag=True)
def remap_cmd(import_job_id: Optional[int], dry_run: bool):
  _log.info('Mapping an AWS import')
  if import_job_id is None:
    raise NotImplementedError('Need to query last import job')
  db = import_session()
  map_import(db, import_job_id)
  import_job = db.query(ImportJob).get(import_job_id)
  refresh_views(db, import_job.provider_account_id)
  if not dry_run:
    db.commit()
  report = report_for_import(db, import_job)
  print(f'Results - Remap of import #{import_job.id}')
  print_report(report)


@cmd.command('remove', help='Remove an AWS account from Gold Fig')
@click.option('-a',
              '--account',
              'account_spec',
              required=True,
              type=str,
              help='The account to be removed')
@click.option('-f',
              '--force',
              required=False,
              default=False,
              is_flag=True,
              help='Skip the prompt before deleting')
@click.option('--dry-run',
              'dry_run',
              default=False,
              is_flag=True,
              help='Do not actually delete anything')
def delete_acct(account_spec: str, dry_run: bool, force: bool):
  db = import_session()
  account = db.query(ProviderAccount).filter(
      ProviderAccount.provider == 'aws',
      ProviderAccount.name == account_spec).one_or_none()
  if account is None:
    raise GFInternal(f'Could not find AWS account {account_spec}')
  remove = force or query_yes_no(
      f'Remove AWS account {account.name} from GoldFig?', default='no')
  if remove:
    report = delete_account(db, account)
    print(f'Removed from AWS account {account.name}')
    for table, count in report.items():
      print(f'{table.ljust(36)}{str(count).rjust(6)} items')
    if not dry_run:
      db.commit()
  else:
    print('Aborting')
    db.rollback()


@cmd.command('list', help='Show all installed AWS accounts')
def list_accounts():
  db = import_session()
  accounts = ProviderAccount.all(db, provider='aws')
  print(
      tabulate([(account.provider, account.name) for account in accounts],
               headers=['Type', 'Account']))
