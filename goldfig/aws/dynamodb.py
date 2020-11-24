import logging
from typing import Any, Dict, Generator, Tuple

from goldfig.aws.fetch import ServiceProxy
from goldfig.aws.svc import RegionalService
from goldfig.error import GFNoAccess

_log = logging.getLogger(__name__)


def _import_table(proxy: ServiceProxy, table_name: str) -> Dict[str, Any]:
  table_resp = proxy.get('describe_table', TableName=table_name)
  if table_resp is None:
    raise GFNoAccess('dynamodb', 'describe_table')
  attrs = table_resp['Table']
  backup_resp = proxy.get('describe_continuous_backups', TableName=table_name)
  if backup_resp is None:
    _log.warn(f'Failed to fetch continuous backups status')
  else:
    backup_desc = backup_resp['ContinuousBackupsDescription']
    for key, value in backup_desc.items():
      attrs[key] = value
  arn = attrs['TableArn']
  tags_resp = proxy.get('list_tags_of_resource', ResourceArn=arn)
  if tags_resp is not None:
    attrs['Tags'] = tags_resp['Tags']
  return attrs


def _import_tables(proxy: ServiceProxy, region: str):
  tables_resp = proxy.list('list_tables')
  if tables_resp is not None:
    table_names = tables_resp[1].get('TableNames', [])
    for table_name in table_names:
      try:
        yield 'Table', _import_table(proxy, table_name)
      except GFNoAccess as e:
        _log.error(f'dynamodb error {region}', exc_info=e)


def _import_backups(proxy: ServiceProxy, region: str):
  backups_resp = proxy.list('list_backups')
  if backups_resp is not None:
    backups = backups_resp[1]['BackupSummaries']
    for backup in backups:
      yield 'Backup', backup


def _import_dynamodb_region(
    proxy: ServiceProxy,
    region: str) -> Generator[Tuple[str, Any], None, None]:
  _log.info(f'importing dynamodb tables {region}')
  yield from _import_tables(proxy, region)
  _log.info(f'importing dynamodb backups {region}')
  yield from _import_backups(proxy, region)


SVC = RegionalService('dynamodb', _import_dynamodb_region)