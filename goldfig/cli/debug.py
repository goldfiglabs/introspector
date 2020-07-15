import os
from pprint import pprint
import sys

import click
import jsonschema
from sqlalchemy.orm.attributes import flag_modified

from goldfig.aws import __file__ as aws_file
from goldfig.account import reset_account
from goldfig.bootstrap_db import import_session
from goldfig.gcp import get_gcloud_credentials, __file__ as gcp_file
from goldfig.mapper import load_transforms, load_transform_schema
from goldfig.models import ImportJob


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
