import concurrent.futures as f
import logging
from typing import Any, Dict, Generator, List, Tuple

from sqlalchemy.orm import Session

from goldfig import ImportWriter, PathStack, db_import_writer
from goldfig.aws import ProxyBuilder, account_paths_for_import, load_boto_session, make_proxy_builder, load_boto_session_from_config
from goldfig.aws.fetch import Proxy, ServiceProxy
from goldfig.bootstrap_db import import_session
from goldfig.models import ImportJob, ProviderCredential

_log = logging.getLogger(__name__)

HAS_TAGS = {
    'describe_db_instances': 'DBInstanceArn',
    'describe_db_clusters': 'DBClusterArn'
}


def _import_rds_region(
    proxy: ServiceProxy) -> Generator[Tuple[str, Any], None, None]:
  for resource in proxy.resource_names():
    _log.info(f'Importing {resource}')
    result = proxy.list(resource)
    if result is not None:
      resource_name, wrapper = result
      items = wrapper.get(resource_name, [])
      arn_for_tags = HAS_TAGS.get(resource)
      if arn_for_tags is not None:
        for item in items:
          arn = item[arn_for_tags]
          tags_result = proxy.list('list_tags_for_resource', ResourceName=arn)
          if tags_result is not None:
            item['Tags'] = tags_result[1].get('TagList', [])
      yield resource_name, items
    _log.info(f'Done with {resource}')


def _import_rds_region_to_db(proxy: Proxy, writer: ImportWriter, ps: PathStack,
                             region: str):
  service_proxy = proxy.service('rds', region)
  ps = ps.scope(region)
  for resource_name, raw_resources in _import_rds_region(service_proxy):
    writer(ps, resource_name, raw_resources, {'region': region})


def import_account_rds_region_to_db(db: Session, import_job_id: int,
                                    region: str, proxy_builder: ProxyBuilder):
  job: ImportJob = db.query(ImportJob).get(import_job_id)
  writer = db_import_writer(db, job.id, 'rds', phase=0, source='base')
  for path, account in account_paths_for_import(db, job):
    boto = load_boto_session(account)
    proxy = proxy_builder(boto)
    ps = PathStack.from_import_job(job).scope(path)
    _import_rds_region_to_db(proxy, writer, ps, region)


def _async_proxy(ps: PathStack, proxy_builder_args, import_job_id: int,
                 region: str, config: Dict):
  db = import_session()
  proxy_builder = make_proxy_builder(*proxy_builder_args)
  boto = load_boto_session_from_config(config)
  proxy = proxy_builder(boto)
  writer = db_import_writer(db, import_job_id, 'rds', phase=0, source='base')
  _import_rds_region_to_db(proxy, writer, ps, region)
  db.commit()


def import_account_rds_region_with_pool(
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