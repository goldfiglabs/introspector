import concurrent.futures as f
import logging
from typing import Dict, List, Tuple

from sqlalchemy.orm import Session

from goldfig import ImportWriter, db_import_writer, PathStack
from goldfig.aws import (load_boto_session, load_boto_session_from_config,
                            account_paths_for_import, ProxyBuilder,
                            make_proxy_builder)
from goldfig.aws.fetch import Proxy, ServiceProxy
from goldfig.bootstrap_db import import_session
from goldfig.models import ImportJob, ProviderCredential

_log = logging.getLogger(__name__)


def import_bucket(proxy: ServiceProxy, bucket_metadata):
  _log.info(f'Importing {bucket_metadata["Name"]}')
  result = bucket_metadata.copy()
  for op_name in proxy.resource_names():
    canonical_name = proxy.canonical_name(op_name)
    if op_name.startswith('list_'):
      list_result = proxy.list(op_name, Bucket=bucket_metadata['Name'])
      if list_result is not None:
        key = canonical_name[len('ListBucket'):]
        result[key] = list_result[1]
      continue
    attr_result = proxy.get(op_name, Bucket=bucket_metadata['Name'])
    if attr_result is not None:
      key = canonical_name[len('GetBucket'):]
      result[key] = attr_result
  return result


def _import_s3(service_proxy: ServiceProxy):
  result = service_proxy.list('list_buckets')
  if result is not None:
    buckets = result[1]
    for bucket in buckets['Buckets']:
      yield import_bucket(service_proxy, bucket)


def import_account_s3_to_db(db: Session, import_job_id: int,
                            proxy_builder: ProxyBuilder):
  job: ImportJob = db.query(ImportJob).get(import_job_id)
  writer = db_import_writer(db, job.id, phase=0)
  for path, account in account_paths_for_import(db, job):
    boto = load_boto_session(account)
    proxy = proxy_builder(boto)
    ps = PathStack.from_import_job(job).scope(path)
    _import_s3_to_db(proxy, writer, ps)


def _import_s3_to_db(proxy: Proxy, writer: ImportWriter, ps: PathStack):
  service_proxy = proxy.service('s3')
  for bucket in _import_s3(service_proxy):
    region = bucket["Location"]["LocationConstraint"]
    writer(ps.scope(region), 'Bucket', bucket)


def _async_proxy(ps: PathStack, proxy_builder_args, import_job_id: int,
                 config: Dict, f):
  db = import_session()
  proxy_builder = make_proxy_builder(*proxy_builder_args)
  boto = load_boto_session_from_config(config)
  proxy = proxy_builder(boto)
  writer = db_import_writer(db, import_job_id, phase=0)
  f(proxy, writer, ps)
  db.commit()


def import_account_s3_with_pool(pool: f.ProcessPoolExecutor,
                                proxy_builder_args, import_job_id: int,
                                ps: PathStack,
                                accounts: List[Tuple[str,
                                                     ProviderCredential]]):
  results: List[f.Future] = []

  def queue_job(fn, path: str, account: ProviderCredential):
    return pool.submit(_async_proxy,
                       proxy_builder_args=proxy_builder_args,
                       import_job_id=import_job_id,
                       ps=ps.scope(path),
                       config=account.config,
                       f=fn)

  for path, account in accounts:
    results.append(queue_job(_import_s3_to_db, path, account))
  return results
