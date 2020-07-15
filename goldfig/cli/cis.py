from typing import Optional

import click

from goldfig.bootstrap_db import readonly_session
from goldfig.tools.cis import ALL_BENCHMARKS, provider_for_spec


@click.command('cis',
               help='Run a selection of the CIS benchmarks against an account')
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
def cmd(provider_spec: Optional[str], tag_spec: str):
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
