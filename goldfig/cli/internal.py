import logging
from pprint import pprint

import click

from goldfig.gcp import (make_proxy_builder, build_gcloud_import_job,
                         credentials_from_config, get_org_graph)


@click.group('internal', hidden=True)
def cmd():
  pass


@cmd.command('gcp-graph')
def build_gcp_graph():
  proxy_builder = make_proxy_builder(use_cache=False, patch_id=None)
  import_desc = build_gcloud_import_job(proxy_builder)
  creds = credentials_from_config(import_desc)
  proxy = proxy_builder(creds)
  org_id = import_desc['account']['account_id']
  principal = import_desc['principal']['provider_id']
  folder_paths, project_paths = get_org_graph(org_id, proxy, principal)
  pprint(folder_paths)
  pprint(project_paths)
  print('done')


@cmd.command('logger-audit')
def logger_audit():
  loggers = [
      logging.getLogger(name) for name in logging.root.manager.loggerDict
  ]
  for logger in loggers:
    level = logger.getEffectiveLevel()
    level_name = logging.getLevelName(level)
    name = logger.name
    if level_name == 'INFO' and not name.startswith('goldfig'):
      print(logger.name, level_name)
