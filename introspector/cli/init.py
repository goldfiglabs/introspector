import os
import shutil
from typing import Optional

import click

from introspector import GOLDFIG_ROOT
from introspector.bootstrap_db import init_db


def _init_db():
  init_db()
  print(f'Introspector successfully inited')


@click.command('init', help='Run this first to set up introspector')
@click.option(
    '--copy-sample-queries/--no-copy-sample-queries',
    'copy_samples',
    help=
    'Passing --copy-sample-queries will copy the sample queries into `cwd`/sample_queries, even if the folder exists. Passing --no-copy-sample-queries will skip this step. The default is to copy only if the folder does not already exist',
    type=bool,
    default=None)
def cmd(copy_samples: Optional[bool]):
  _init_db()