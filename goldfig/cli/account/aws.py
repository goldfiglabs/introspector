import logging
import textwrap
from typing import Optional

import click
from sqlalchemy.orm import Session
from tabulate import tabulate

from goldfig.account import delete_account
from goldfig.aws import (build_aws_import_job, make_proxy_builder, map_import,
                         ProxyBuilder, run_single_session,
                         create_provider_and_credential, run_parallel_session,
                         account_paths_for_import, get_boto_session)
from goldfig.bootstrap_db import import_session, refresh_views
from goldfig.cli.util import print_report, query_yes_no
from goldfig.delta.report import report_for_import
from goldfig.error import GFError, GFInternal
from goldfig.models import ProviderAccount, ImportJob

_log = logging.getLogger(__name__)


def _add_account_interactive(db: Session, proxy_builder: ProxyBuilder,
                             force: bool) -> ProviderAccount:
  boto_session = get_boto_session()
  creds = boto_session.get_credentials()
  if creds is not None:
    sts = boto_session.create_client('sts')
    identity = sts.get_caller_identity()
    add = force or query_yes_no(
        f'Add AWS account {identity["Account"]} using identity {identity["Arn"]}?',
        default='yes')
    if not add:
      raise GFError('User cancelled')
    proxy = proxy_builder(boto_session)
    return create_provider_and_credential(db, proxy, identity)
  else:
    # TODO: point to docs on specifying credentials
    msg = textwrap.dedent('''
      No AWS credentials found. Please set up AWS credentials
      as described here:

      https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html#cli-configure-quickstart-config
    ''')
    raise GFError(msg)


def _find_provider(db: Session,
                   proxy_builder: ProxyBuilder,
                   account_spec: Optional[str],
                   force: bool = False) -> ProviderAccount:
  if account_spec is None:
    accounts = db.query(ProviderAccount).filter(
        ProviderAccount.provider == 'aws').all()
    if len(accounts) > 1:
      # TODO: better error / print out available accounts
      accounts_str = '\n'.join([account.name for account in accounts])
      msg = 'No account specified, but more than one AWS account exists. Existing accounts:\n' + accounts_str
      raise GFError(msg)
    elif len(accounts) == 1:
      return accounts[0]
    else:
      return _add_account_interactive(db, proxy_builder, force)
  else:
    raise NotImplementedError('cannot specify account yet')


@click.group('aws', help='Tools for AWS accounts')
def cmd():
  pass


@cmd.command('import',
             help='Imports the assets from an AWS account into Gold Fig')
@click.option(
    '-a',
    '--account',
    required=False,
    type=str,
    default=None,
    help=
    'Specify which AWS account to add. Required if more than one AWS account has been added to Gold Fig'
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
def import_aws_cmd(account: Optional[str], debug: bool,
                   patch_id: Optional[int], use_cache: bool, force: bool,
                   dry_run: bool):
  db = import_session()
  proxy_builder_args = (use_cache, patch_id)
  proxy_builder = make_proxy_builder(*proxy_builder_args)
  provider = _find_provider(db, proxy_builder, account, force=force)
  import_desc = build_aws_import_job(db, proxy_builder, provider)
  import_job = ImportJob.create(provider, import_desc)
  db.add(import_job)
  db.flush()
  if debug:
    run_single_session(db, import_job.id, proxy_builder)
    db.flush()
    map_import(db, import_job.id, proxy_builder)
    refresh_views(db)
    if not dry_run:
      db.commit()
    print('done', import_job.id)
  else:
    accounts = account_paths_for_import(db, import_job)
    db.commit()
    # No db required for parallel invocation
    exceptions = run_parallel_session(accounts, import_job, proxy_builder_args)
    # Re-open db for mapping
    db = import_session()
    if len(exceptions) == 0:
      map_import(db, import_job.id, proxy_builder)
      refresh_views(db)
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
  _log.info('Mapping an AWS import')
  if import_job_id is None:
    raise NotImplementedError('Need to query last import job')
  proxy_builder = make_proxy_builder(use_cache, patch_id)
  db = import_session()
  map_import(db, import_job_id, proxy_builder)
  refresh_views(db)
  if not dry_run:
    db.commit()
  import_job = db.query(ImportJob).get(import_job_id)
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
