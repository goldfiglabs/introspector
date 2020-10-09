import logging
import sys
from typing import List

import click

from goldfig.cli.account import cmd as account
from goldfig.cli.cis import cmd as cis
from goldfig.cli.debug import cmd as debug
from goldfig.cli.init import cmd as init
from goldfig.cli.internal import cmd as internal
from goldfig.cli.meta import cmd as meta
from goldfig.cli.query import cmd as query
from goldfig.cli.serve import cmd as serve
from goldfig.cli.status import cmd as status
from goldfig.cli.tags import cmd as tags
from goldfig.error import GFError


@click.group()
def cli():
  pass


cli.add_command(init)
cli.add_command(internal)
cli.add_command(status)
cli.add_command(meta)
cli.add_command(debug)
cli.add_command(tags)
cli.add_command(query)
cli.add_command(cis)
cli.add_command(account)
cli.add_command(serve)

DEBUG = True


def _setup_logging():
  # TODO: real logging config
  if DEBUG:
    log_format = '[%(asctime)s] {%(filename)s:%(lineno)d} %(levelname)s - %(message)s'
    logging.basicConfig(level=logging.INFO, format=log_format)
    logging.getLogger('goldfig').setLevel(logging.INFO)
    # AWS
    logging.getLogger('botocore').setLevel(logging.WARN)
    logging.getLogger('bcdocs').setLevel(logging.WARN)
    # GCP
    logging.getLogger('google').setLevel(logging.WARN)
    logging.getLogger('googleapiclient').setLevel(logging.WARN)
    logging.getLogger('google_auth_httplib2').setLevel(logging.WARN)
    # stdlib
    logging.getLogger('rsa').setLevel(logging.WARN)
    logging.getLogger('urllib3').setLevel(logging.WARN)
  else:
    log_format = '[%(asctime)s] %(levelname)s - %(message)s'
    logging.basicConfig(level=logging.WARN, format=log_format)


def run_cli():
  _setup_logging()
  try:
    cli()
    exit_code = 0
  except GFError as e:
    sys.stderr.write('An error occurred\n')
    sys.stderr.write(e.message)
    sys.stderr.write('\n')
    exit_code = 2
    if DEBUG:
      raise e
  sys.exit(exit_code)
