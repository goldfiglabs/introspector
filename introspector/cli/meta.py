import click
from tabulate import tabulate

from introspector.bootstrap_db import readonly_session


@click.group('meta', hidden=True)
def cmd():
  pass


@cmd.command('status')
def show_status():
  db = readonly_session()
  result = db.execute('''
    SELECT
      PA.id AS id,
      PA.name AS account,
      PA.provider AS provider,
      MAX(IJ.id) AS recent_import_id
    FROM
      provider_account AS PA,
      import_job AS IJ
    WHERE
      IJ.provider_account_id = PA.id
    GROUP BY PA.id
  ''')
  headers = ['Id', 'Account', 'Provider', 'Recent Import Id']
  print(tabulate(result, headers=headers))
