import logging

import click


@click.group('internal', hidden=True)
def cmd():
  pass


@cmd.command('logger-audit')
def logger_audit():
  loggers = [
      logging.getLogger(name) for name in logging.root.manager.loggerDict
  ]
  for logger in loggers:
    level = logger.getEffectiveLevel()
    level_name = logging.getLevelName(level)
    name = logger.name
    if level_name == 'INFO' and not name.startswith('introspector'):
      print(logger.name, level_name)
