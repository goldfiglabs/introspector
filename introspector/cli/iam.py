import click
from typing import Tuple

from introspector.bootstrap_db import readonly_session
from introspector.tools.iam_policy_permissions import find_permissions


@click.group('iam', help='Tools for working with AWS IAM')
def cmd():
  pass


@cmd.command(
    'show-permissions',
    help=
    'Show the specific permissions unconditionally allowed by a set of policies'
)
@click.option('--show-policy',
              type=bool,
              required=False,
              default=False,
              is_flag=True,
              help='Also print the policies that allow the specific permission'
              )
@click.argument('policies', nargs=-1, required=True)
def show_permissions(policies: Tuple[str], show_policy: bool):
  db = readonly_session()
  results = find_permissions(db, policies)
  for result in results:
    if show_policy:
      print(result['action'], ', '.join(result['policies']))
    else:
      print(result['action'])