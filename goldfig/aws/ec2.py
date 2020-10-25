import concurrent.futures as f
import logging
from typing import Any, Dict, Generator, Iterator, List, Tuple

from sqlalchemy.orm import Session

from goldfig import ImportWriter, db_import_writer, PathStack
from goldfig.aws import (account_paths_for_import, load_boto_session,
                         load_boto_session_from_config)
from goldfig.aws.fetch import Proxy, ServiceProxy
from goldfig.bootstrap_db import import_session
from goldfig.models import ImportJob, ProviderCredential

_log = logging.getLogger(__name__)


def _synthesize_defaults(proxy: ServiceProxy,
                         region: str) -> Iterator[Tuple[str, Any]]:
  defaults = {'name': 'Defaults', 'uri': f'ec2/defaults/{region}'}
  # TODO: update permissions
  # key_id_resp = proxy.get('get_ebs_default_kms_key_id')
  # defaults['EbsDefaultKmsKeyId'] = key_id_resp.get('KmsKeyId')
  encryption_resp = proxy.get('get_ebs_encryption_by_default')
  defaults['EbsEncryptionByDefault'] = encryption_resp[
      'EbsEncryptionByDefault']
  yield 'Defaults', defaults


def _import_ec2_region(proxy: ServiceProxy,
                       region: str) -> Generator[Tuple[str, Any], None, None]:
  for resource in proxy.resource_names():
    _log.info(f'importing {resource}')
    result = proxy.list(resource)
    if result is not None:
      yield result[0], result[1]
    _log.info(f'done with {resource}')
  yield from _synthesize_defaults(proxy, region)


def import_account_ec2_region_to_db(db: Session, import_job_id: int,
                                    region: str):
  job: ImportJob = db.query(ImportJob).get(import_job_id)
  writer = db_import_writer(db, job.id, 'ec2', phase=0, source='base')
  for path, account in account_paths_for_import(db, job):
    boto = load_boto_session(account)
    proxy = Proxy.build(boto)
    ps = PathStack.from_import_job(job).scope(path)
    _import_ec2_region_to_db(proxy, writer, ps, region)


def _import_ec2_region_to_db(proxy: Proxy, writer: ImportWriter, ps: PathStack,
                             region: str):
  service_proxy = proxy.service('ec2', region)
  ps = ps.scope(region)
  for resource_name, raw_resources in _import_ec2_region(
      service_proxy, region):
    writer(ps, resource_name, raw_resources, {'region': region})


def _async_proxy(ps: PathStack, import_job_id: int, region: str, config: Dict,
                 f):
  db = import_session()
  boto = load_boto_session_from_config(config)
  proxy = Proxy.build(boto)
  writer = db_import_writer(db, import_job_id, 'ec2', phase=0, source='base')
  f(proxy, writer, ps, region)
  db.commit()


def import_account_ec2_region_with_pool(
    pool: f.ProcessPoolExecutor, import_job_id: int, region: str,
    ps: PathStack, accounts: List[Tuple[str, ProviderCredential]]):
  results: List[f.Future] = []

  def queue_job(fn, path: str, account: ProviderCredential):
    return pool.submit(_async_proxy,
                       import_job_id=import_job_id,
                       region=region,
                       ps=ps.scope(path),
                       config=account.config,
                       f=fn)

  for path, account in accounts:
    results.append(queue_job(_import_ec2_region_to_db, path, account))
  return results


def add_amis_to_import_job(proxy: Proxy, writer: ImportWriter, ps: PathStack,
                           region: str, amis: List[str]) -> str:
  ps = ps.scope(region)
  service_proxy = proxy.service('ec2', region)
  result = service_proxy.list(
      'describe_images',
      ImageIds=amis,
      # Remove the default filters
      Filters=[])
  _log.debug(f'describe images result {result}')
  if result is not None:
    resource_name = result[0]
    raw_resources = result[1]
    writer(ps, resource_name, raw_resources, {'region': region})
  return ps.path()
