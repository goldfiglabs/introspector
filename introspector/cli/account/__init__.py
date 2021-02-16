import click
from tabulate import tabulate

from introspector.bootstrap_db import readonly_session
from introspector.cli.account.aws import cmd as aws
from introspector.models import ProviderAccount


@click.group('account',
             help='Tools for working with accounts connected to introspector')
def cmd():
  pass


cmd.add_command(aws)


@cmd.command('list', help='Show all installed accounts')
def list_accounts():
  db = readonly_session()
  accounts = ProviderAccount.all(db)
  print(
      tabulate([(account.provider, account.name) for account in accounts],
               headers=['Type', 'Account']))
