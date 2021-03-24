import logging
import sys

import click

from introspector.cli.account import cmd as account
from introspector.cli.cis import cmd as cis
from introspector.cli.debug import cmd as debug
from introspector.cli.iam import cmd as iam
from introspector.cli.init import cmd as init
from introspector.cli.internal import cmd as internal
from introspector.cli.meta import cmd as meta
from introspector.cli.query import cmd as query
from introspector.cli.serve import cmd as serve
from introspector.cli.status import cmd as status
from introspector.cli.tags import cmd as tags
from introspector.error import GFError


@click.group()
def cli():
  pass


cli.add_command(init)
cli.add_command(internal)
cli.add_command(status)
cli.add_command(meta)
cli.add_command(debug)
cli.add_command(iam)
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
    logging.basicConfig(level=logging.WARN, format=log_format)
    logging.getLogger('introspector').setLevel(logging.INFO)
    # AWS
    logging.getLogger('botocore').setLevel(logging.WARN)
    logging.getLogger('bcdocs').setLevel(logging.WARN)
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
