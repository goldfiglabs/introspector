import concurrent.futures as f
import logging
from typing import Any, Dict, Generator, List, Tuple

from sqlalchemy.orm import Session

from goldfig import ImportWriter, db_import_writer, PathStack
from goldfig.aws import (account_paths_for_import, load_boto_session,
                         ProxyBuilder, make_proxy_builder,
                         load_boto_session_from_config)
from goldfig.aws.fetch import Proxy, ServiceProxy
from goldfig.bootstrap_db import import_session
from goldfig.models import ImportJob, ProviderCredential

_log = logging.getLogger(__name__)


def import_account_lambda_region_to_db(db: Session, import_job_id: int,
                                       region: str,
                                       proxy_builder: ProxyBuilder):
  job: ImportJob = db.query(ImportJob).get(import_job_id)
  writer = db_import_writer(db, job.id, 'lambda', phase=0)
  for path, account in account_paths_for_import(db, job):
    boto = load_boto_session(account)
    proxy = proxy_builder(boto)
    ps = PathStack.from_import_job(job).scope(path)
    _import_lambda_region_to_db(proxy, writer, ps, region)


def _import_lambda_region_to_db(proxy: Proxy, writer: ImportWriter,
                                ps: PathStack, region: str):
  service_proxy = proxy.service('lambda', region)
  ps = ps.scope(region)
  for resource_name, raw_resources in _import_lambda_region(service_proxy):
    writer(ps, resource_name, raw_resources, {'region': region})


def _import_lambda_region(
    proxy: ServiceProxy) -> Generator[Tuple[str, Any], None, None]:
  for resource in proxy.resource_names():
    _log.info(f'importing {resource}')
    result = proxy.list(resource)
    if result is not None:
      yield result[0], result[1]
    _log.info(f'done with {resource}')


def _async_proxy(ps: PathStack, proxy_builder_args, import_job_id: int,
                 region: str, config: Dict):
  db = import_session()
  proxy_builder = make_proxy_builder(*proxy_builder_args)
  boto = load_boto_session_from_config(config)
  proxy = proxy_builder(boto)
  writer = db_import_writer(db, import_job_id, 'lambda', phase=0)
  _import_lambda_region_to_db(proxy, writer, ps, region)
  db.commit()


def import_account_lambda_region_with_pool(
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