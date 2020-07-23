import logging
from typing import Dict, Optional

import click
from sqlalchemy.orm import Session
from tabulate import tabulate

from goldfig.account import delete_account
from goldfig.bootstrap_db import refresh_views, import_session
from goldfig.cli.util import print_report, query_yes_no
from goldfig.delta.report import report_for_import
from goldfig.error import GFError, GFInternal
from goldfig.gcp import (build_gcloud_import_job, get_gcloud_credentials,
                         get_gcloud_user, make_proxy_builder, map_import,
                         run_single_session, add_account_interactive,
                         add_graph_to_import_job, run_parallel_session,
                         gcp_auth_env)
from goldfig.models import ProviderAccount, ImportJob

_log = logging.getLogger(__name__)


def _find_provider(db: Session, org: Dict, account_spec: Optional[str],
                   force: bool) -> ProviderAccount:
  org_id = org['name'].split('/')[1]
  if account_spec is not None and account_spec != org_id:
    raise GFError(
        f'GCP organization {org_id} was requested but current gcloud credentials are for {org_id}'
    )
  account = db.query(ProviderAccount).filter(
      ProviderAccount.provider == 'gcp',
      ProviderAccount.name == org_id).one_or_none()
  if account is None:
    return add_account_interactive(db, org_id, org['displayName'], force)
  else:
    return account


@click.group('gcp', help='Tools for GCP accounts')
def cmd():
  pass


@cmd.command('import',
             help='Imports the assets from a GCP account into Gold Fig')
@click.option(
    '-a',
    '--account',
    required=False,
    type=str,
    default=None,
    help=
    'Specify which GCP account to add. Required if more than one GCP account has been added to Gold Fig'
)
@click.option('-d', '--debug', 'debug', default=False, type=bool, hidden=True)
@click.option('-p',
              '--patch-id',
              'patch_id',
              default=None,
              type=int,
              hidden=True)
@click.option('-c',
              '--use-cache/--no-use-cache',
              'use_cache',
              default=False,
              hidden=True,
              type=bool)
@click.option('-f',
              '--force',
              'force',
              default=False,
              is_flag=True,
              help='Skip prompts for adding accounts')
@click.option('--dry-run', 'dry_run', default=False, hidden=True, is_flag=True)
def import_gcp_cmd(account: Optional[str], debug: bool,
                   patch_id: Optional[int], use_cache: bool, force: bool,
                   dry_run: bool):
  _log.info('Importing GCP')
  proxy_builder_args = (use_cache, patch_id)
  proxy_builder = make_proxy_builder(*proxy_builder_args)
  db = import_session()
  with gcp_auth_env():
    import_desc = build_gcloud_import_job(proxy_builder)
    provider = _find_provider(db, import_desc['gcp_org'], account, force=force)
    import_job = ImportJob.create(provider, import_desc)
    db.add(import_job)
    db.flush()
    if debug:
      run_single_session(db, import_job.id, proxy_builder)
      db.flush()
      map_import(db, import_job.id, proxy_builder)
      refresh_views(db)
      import_job.mark_complete(exceptions=[])
      db.add(import_job)
      if not dry_run:
        db.commit()
    else:
      add_graph_to_import_job(db, import_job.id, proxy_builder)
      db.commit()
      # No db required for parallel invocation
      exceptions = run_parallel_session(import_job, proxy_builder_args)
      # Make certain we're using the current db session
      import_job = db.query(ImportJob).get(import_job.id)
      if len(exceptions) == 0:
        map_import(db, import_job.id, proxy_builder)
        refresh_views(db)
        import_job.mark_complete(exceptions=[])
      else:
        import_job.mark_complete(exceptions)
        print(exceptions)
      db.add(import_job)
      db.commit()
  report = report_for_import(db, import_job)
  print(f'Results - Import #{import_job.id}')
  print_report(report)
  _log.info(f'imported {import_job.id}')


@cmd.command('remap', hidden=True)
@click.option(
    '-i',
    '--import_job',
    'import_job_id',
    help=
    'Remap a specific import. If not specified, the last import will be used',
    type=int,
    default=None)
@click.option('-p',
              '--patch-id',
              'patch_id',
              default=None,
              type=int,
              hidden=True)
@click.option('-c',
              '--use-cache/--no-use-cache',
              'use_cache',
              default=False,
              hidden=True,
              type=bool)
@click.option('--dry-run', 'dry_run', default=False, hidden=True, is_flag=True)
def remap_cmd(import_job_id: Optional[int], use_cache: bool,
              patch_id: Optional[int], dry_run: bool):
  if import_job_id is None:
    raise NotImplementedError('Need to query last import job')
  _log.info('Mapping a GCP import')
  proxy_builder = make_proxy_builder(use_cache, patch_id)
  db = import_session()
  with gcp_auth_env():
    map_import(db, import_job_id, proxy_builder)
  refresh_views(db)
  if not dry_run:
    db.commit()
  import_job = db.query(ImportJob).get(import_job_id)
  report = report_for_import(db, import_job)
  print(f'Results - Remap of import #{import_job.id}')
  print_report(report)


@cmd.command('credential', hidden=True)
def check_credential():
  import os
  gcp_auth = os.environ.get('GOLDFIG_GCP_AUTH')
  if gcp_auth is not None:
    print('gcp auth', gcp_auth)
  else:
    print('missing env')
  with gcp_auth_env():
    creds = get_gcloud_credentials()
    print(creds.to_json())
    user = get_gcloud_user(creds)
    print(user)


@cmd.command('list', help='Show all installed GCP accounts')
def list_accounts():
  db = import_session()
  accounts = ProviderAccount.all(db, provider='gcp')
  print(
      tabulate([(account.provider, account.name) for account in accounts],
               headers=['Type', 'Account']))


@cmd.command('remove', help='Remove a GCP account from Gold Fig')
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
      ProviderAccount.provider == 'gcp',
      ProviderAccount.name == account_spec).one_or_none()
  if account is None:
    raise GFInternal(f'Could not find GCP account {account_spec}')
  remove = force or query_yes_no(
      f'Remove GCP account {account.name} from GoldFig?', default='no')
  if remove:
    report = delete_account(db, account)
    print(f'Removed from GCP account {account.name}')
    for table, count in report.items():
      print(f'{table.ljust(36)}{str(count).rjust(6)} items')
    if not dry_run:
      db.commit()
  else:
    print('Aborting')
    db.rollback()
