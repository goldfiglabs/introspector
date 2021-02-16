from introspector.tools.cis import aws_foundation
from typing import Optional

import click

from introspector.cli.provider import provider_scoped_db
import introspector.tools.cis.aws_foundation as aws_foundation


@click.group('cis',
             help='Run a selection of the CIS benchmarks against an account')
def cmd():
  pass


@cmd.command('foundation', help='Run the AWS Foundation CIS Benchmark')
@click.option(
    '-p',
    '--provider',
    'provider_spec',
    required=False,
    default=None,
    help=
    'An optional identifier for which account to benchmark. Required if more than one account has been imported'
)
def foundation(provider_spec: Optional[str]):
  scoped_db = provider_scoped_db(provider_spec)
  aws_foundation.run(scoped_db.db, scoped_db.provider_account_id)