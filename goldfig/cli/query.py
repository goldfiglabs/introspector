import os
from typing import Generator

import click
from tabulate import tabulate

from goldfig.bootstrap_db import readonly_session
from goldfig.tools.query import run_query


def _directory_queries(dir_path: str) -> Generator[str, None, None]:
  for filename in os.listdir(dir_path):
    with open(os.path.join(dir_path, filename), 'r') as f:
      yield f.read()


@click.command(
    'run',
    help=
    '''Runs QUERY_SOURCE, which should be the name of a file containing the query to run, or a directory of such files, or a literal SQL query'''
)
@click.argument('query_source', required=True, type=str)
def cmd(query_source: str):
  if os.path.isfile(query_source):
    with open(query_source, 'r') as f:
      queries = [f.read()]
  elif os.path.isdir(query_source):
    queries = _directory_queries(query_source)
  else:
    queries = [query_source]
  db = readonly_session()
  for query in queries:
    results = run_query(db, query)
    print(tabulate(results.rows, headers=results.columns))
