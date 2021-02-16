from typing import Optional

import click

from introspector.cli.provider import provider_scoped_db
from introspector.models import ProviderAccount
from introspector.tools.tags import find_untagged, tag_report


@click.group('tags', help='Tools for working with tagged resources')
def cmd():
  pass


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
  scoped_db = provider_scoped_db(provider_spec)
  provider = scoped_db.db.query(ProviderAccount).get(
      scoped_db.provider_account_id)
  print(f'Untagged resources for {provider.provider} account {provider.name}')
  uris = find_untagged(scoped_db.db, provider.id)
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
  scoped_db = provider_scoped_db(provider_spec)
  provider = scoped_db.db.query(ProviderAccount).get(
      scoped_db.provider_account_id)
  report = tag_report(scoped_db.db, provider.id)
  print(f'Tags in {provider.provider} account {provider.name}')
  if len(report) == 0:
    print('NONE')
  else:
    for key, values in report.items():
      sanitized = [_sanitize(s) for s in values]
      print(f'({len(sanitized)}) ' + key.ljust(30) + ',  '.join(sanitized))
