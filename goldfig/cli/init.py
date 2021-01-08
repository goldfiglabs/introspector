import os
import shutil
from typing import Optional

import click

from goldfig import GOLDFIG_ROOT
from goldfig.bootstrap_db import init_db


def _copy_sample_queries(copy_sample: Optional[bool]):
  if copy_sample == False:
    print('Skipping copying sample queries')
    return
  this_dir = os.getcwd()
  dest_dir = os.path.join(this_dir, 'sample_queries')
  dest_exists = os.path.exists(dest_dir)
  if dest_exists and copy_sample != True:
    print(f'Skipping copying sample queries, {dest_dir} already exists')
    return
  elif not dest_exists:
    os.mkdir(dest_dir)
  src_dir = os.path.join(GOLDFIG_ROOT, 'sample_queries')
  for f in os.listdir(src_dir):
    src = os.path.join(src_dir, f)
    dst = os.path.join(dest_dir, f)
    shutil.copy(src, dst)
  print(f'Sample queries copied to {dest_dir}')


def _init_db():
  init_db()
  print(f'Goldfig successfully inited')


@click.command('init', help='Run this first to set up Gold Fig')
@click.option(
    '--copy-sample-queries/--no-copy-sample-queries',
    'copy_samples',
    help=
    'Passing --copy-sample-queries will copy the sample queries into `cwd`/sample_queries, even if the folder exists. Passing --no-copy-sample-queries will skip this step. The default is to copy only if the folder does not already exist',
    type=bool,
    default=None)
def cmd(copy_samples: Optional[bool]):
  _init_db()
  _copy_sample_queries(copy_samples)