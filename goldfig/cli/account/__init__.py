import click
from tabulate import tabulate

from goldfig.bootstrap_db import readonly_session
from goldfig.cli.account.aws import cmd as aws
from goldfig.cli.account.gcp import cmd as gcp
from goldfig.models import ProviderAccount


@click.group('account',
             help='Tools for working with accounts connected to Gold Fig')
def cmd():
  pass


cmd.add_command(gcp)
cmd.add_command(aws)


@cmd.command('list', help='Show all installed accounts')
def list_accounts():
  db = readonly_session()
  accounts = ProviderAccount.all(db)
  print(
      tabulate([(account.provider, account.name) for account in accounts],
               headers=['Type', 'Account']))
