from goldfig.tools.cis import aws_foundation
from typing import Optional

import click

from goldfig.bootstrap_db import readonly_session
from goldfig.tools.cis import ALL_BENCHMARKS, provider_for_spec
import goldfig.tools.cis.aws_foundation as aws_foundation


@click.group('cis',
             help='Run a selection of the CIS benchmarks against an account')
def cmd():
  pass


@cmd.command('3-tier')
@click.option(
    '-p',
    '--provider',
    'provider_spec',
    required=False,
    default=None,
    help=
    'An optional identifier for which account to benchmark. Required if more than one account has been imported'
)
@click.option(
    '-t',
    '--tags',
    'tag_spec',
    required=True,
    type=str,
    help=
    'A comma-separated list of key-value pairs specifying the architecture tier tags for the benchmark. Example --tags role=web,role=app'
)
def three_tier(provider_spec: Optional[str], tag_spec: str):
  db = readonly_session()
  tags = []
  for pair in tag_spec.split(','):
    k, v = pair.split('=')
    tags.append((k, v))
  # TODO: make quick helper class for TierTag
  provider = provider_for_spec(db, provider_spec)
  for benchmark in ALL_BENCHMARKS:
    b = benchmark()
    print('\n', b)
    for tag in tags:
      results = b.exec_explain(db, provider.id, tag)
      print(results)


@cmd.command('foundation', hidden=True)
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
  db = readonly_session()
  provider = provider_for_spec(db, provider_spec)
  aws_foundation.run(db, provider)