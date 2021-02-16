import os
from pprint import pprint
import sys
from typing import Optional

import click
import jsonschema

from introspector.aws import __file__ as aws_file, account_paths_for_import
from introspector.aws.map import _get_mapper
from introspector.aws.uri import get_arn_fn
from introspector.account import reset_account
from introspector.bootstrap_db import import_session, readonly_session, refresh_views
from introspector.cli.provider import provider_for_spec
from introspector.mapper import load_transforms, load_transform_schema
from introspector.models import ImportJob, RawImport


@click.group('debug', hidden=True)
def cmd():
  pass


@cmd.command('reset')
@click.option(
    '-p',
    '--provider-account',
    'provider_account',
    required=True,
    type=int,
    help='The id of the provider account to reset',
)
def reset_provider_account(provider_account: int):
  db = import_session()
  report = reset_account(db, provider_account)
  db.commit()
  pprint(report)


def _validate_provider_transforms(module_base: str, name: str, schema):
  path = os.path.join(os.path.dirname(module_base), 'transforms')
  transforms = load_transforms(path)
  for key, transform in transforms.items():
    sys.stdout.write(f'Validating {name} {key}...')
    try:
      jsonschema.validate(transform, schema=schema)
      sys.stdout.write('PASS\n')
    except jsonschema.ValidationError as e:
      print(name, key, 'failed validation')
      raise e


@cmd.command('validate', help='Validate the transform files')
def validate_transforms():
  schema = load_transform_schema()
  _validate_provider_transforms(aws_file, 'aws', schema)
  print('done')


@cmd.command('reinstall-views', help='Rerun all of the view files')
@click.option(
    '-p',
    '--provider',
    'provider_spec',
    required=False,
    default=None,
    help=
    'An optional identifier for which account to benchmark. Required if more than one account has been imported'
)
def reinstall_views(provider_spec: Optional[str]):
  db = import_session()
  provider_account_id = provider_for_spec(db, provider_spec)
  refresh_views(db, provider_account_id)


@cmd.command('map-resource', help='Try mapping a specific raw import')
@click.argument('import_id', type=int, required=True)
def map_resource(import_id: int):
  db = readonly_session()
  raw = db.query(RawImport).get(import_id)
  if raw is None:
    raise RuntimeError('Unknown RawImport')
  import_job = db.query(ImportJob).get(raw.import_job_id)
  if import_job is None:
    raise RuntimeError('Unknown import job')
  mapper = _get_mapper(import_job)
  print(raw.raw_resources())
  import_resource_name = raw.resource_name
  _, creds = account_paths_for_import(db, import_job)[0]
  uri_fn = get_arn_fn(creds.scope, partition='aws')
  results = list(
      mapper.map_resources(raw.raw_resources(), raw.context, raw.service,
                           import_resource_name, uri_fn))
  print(results)


@cmd.command('rds')
def try_rds():
  import_session()