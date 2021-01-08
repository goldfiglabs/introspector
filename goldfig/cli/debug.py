import os
from pprint import pprint
import sys
from typing import Optional

import click
import jsonschema
from sqlalchemy.orm.attributes import flag_modified

from goldfig.aws import __file__ as aws_file, account_paths_for_import
from goldfig.aws.map import _get_mapper
from goldfig.aws.uri import get_arn_fn
from goldfig.account import reset_account
from goldfig.bootstrap_db import import_session, install_views, readonly_session, refresh_views
from goldfig.cli.provider import provider_for_spec
from goldfig.gcp import get_gcloud_credentials, __file__ as gcp_file
from goldfig.mapper import load_transforms, load_transform_schema
from goldfig.models import ImportJob, RawImport


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


@cmd.command('reauth-gcp', help='Update the auth tokens in a gcp import job')
@click.option('-i',
              '--import-job',
              'import_job_id',
              type=int,
              required=True,
              help='The import job to refresh')
def bump_gcp_creds(import_job_id: int):
  id_token, access_token = get_gcloud_credentials()
  db = import_session()
  import_job: ImportJob = db.query(ImportJob).get(import_job_id)
  import_job.configuration['credentials']['id_token'] = id_token
  import_job.configuration['credentials']['access_token'] = access_token
  flag_modified(import_job, 'configuration')
  db.add(import_job)
  db.commit()


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
  _validate_provider_transforms(gcp_file, 'gcp', schema)
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
  import_job: ImportJob = db.query(ImportJob).get(raw.import_job_id)
  mapper = _get_mapper(import_job)
  print(raw.raw_resources())
  import_resource_name = raw.resource_name
  _, creds = account_paths_for_import(db, import_job)[0]
  uri_fn = get_arn_fn(creds.scope)
  results = list(
      mapper.map_resources(raw.raw_resources(), raw.context, raw.service,
                           import_resource_name, uri_fn))
  print(results)
