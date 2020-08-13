import concurrent.futures as f
import logging
from typing import Any, Dict, Iterator, List, Tuple

from sqlalchemy.orm import Session

from goldfig import db_import_writer, ImportWriter, PathStack
from goldfig.aws import (account_paths_for_import, make_proxy_builder,
                         load_boto_session, load_boto_session_from_config,
                         ProxyBuilder)
from goldfig.aws.fetch import Proxy, ServiceProxy
from goldfig.bootstrap_db import import_session
from goldfig.models import ImportJob, ProviderCredential

_log = logging.getLogger(__name__)


def _import_alarm(proxy: ServiceProxy, alarm_data: Dict):
  arn = alarm_data['AlarmArn']
  tags_result = proxy.list('list_tags_for_resource', ResourceARN=arn)
  if tags_result is not None:
    alarm_data['Tags'] = tags_result[1]['Tags']
  return alarm_data


def _import_alarms(proxy: ServiceProxy, region: str):
  alarms_resp = proxy.list('describe_alarms',
                           AlarmTypes=['MetricAlarm', 'CompositeAlarm'])
  if alarms_resp is not None:
    metric_alarms = alarms_resp[1]['MetricAlarms']
    for alarm in metric_alarms:
      yield 'MetricAlarm', _import_alarm(proxy, alarm)
    composite_alarms = alarms_resp[1]['CompositeAlarms']
    for alarm in composite_alarms:
      yield 'CompositeAlarm', _import_alarm(proxy, alarm)


def import_account_cloudwatch_region_to_db(db: Session, import_job_id: int,
                                           region: str,
                                           proxy_builder: ProxyBuilder):
  job: ImportJob = db.query(ImportJob).get(import_job_id)
  writer = db_import_writer(db, job.id, 'cloudwatch', phase=0, source='base')
  for path, account in account_paths_for_import(db, job):
    boto = load_boto_session(account)
    proxy = proxy_builder(boto)
    ps = PathStack.from_import_job(job).scope(path)
    _import_cloudwatch_region_to_db(proxy, writer, ps, region)


def _async_proxy(ps: PathStack, proxy_builder_args, import_job_id: int,
                 region: str, config: Dict):
  db = import_session()
  proxy_builder = make_proxy_builder(*proxy_builder_args)
  boto = load_boto_session_from_config(config)
  proxy = proxy_builder(boto)
  writer = db_import_writer(db,
                            import_job_id,
                            'cloudwatch',
                            phase=0,
                            source='base')
  _import_cloudwatch_region_to_db(proxy, writer, ps, region)
  db.commit()


def _import_cloudwatch_region_to_db(proxy: Proxy, writer: ImportWriter,
                                    ps: PathStack, region: str):
  service_proxy = proxy.service('cloudwatch', region)
  ps = ps.scope(region)
  for resource_name, raw_resources in _import_cloudwatch_region(
      service_proxy, region):
    writer(ps, resource_name, raw_resources, {'region': region})


def _import_cloudwatch_region(proxy: ServiceProxy,
                              region: str) -> Iterator[Tuple[str, Any]]:
  _log.info(f'import alarms in {region}')
  yield from _import_alarms(proxy, region)


def import_account_cloudwatch_region_with_pool(
    pool: f.ProcessPoolExecutor, proxy_builder_args, import_job_id: int,
    region: str, ps: PathStack,
    accounts: List[Tuple[str, ProviderCredential]]) -> List[f.Future]:
  results: List[f.Future] = []

  def queue_job(path: str, account: ProviderCredential) -> f.Future:
    return pool.submit(_async_proxy,
                       proxy_builder_args=proxy_builder_args,
                       import_job_id=import_job_id,
                       region=region,
                       ps=ps.scope(path),
                       config=account.config)

  for path, account in accounts:
    results.append(queue_job(path, account))
  return results