import click

from goldfig.server import run_webserver


@click.command('serve', help='Runs a local webserver', hidden=True)
def cmd():
  run_webserver()