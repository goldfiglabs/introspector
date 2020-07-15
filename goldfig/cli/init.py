import click

from goldfig.bootstrap_db import init_db, SCHEMA_VERSION


@click.command('init', help='Run this first to set up Gold Fig')
def cmd():
  init_db()
  print(f'Goldfig successfully inited with schema version {SCHEMA_VERSION}')
