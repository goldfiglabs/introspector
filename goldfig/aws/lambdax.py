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

HAS_TAGS = {'list_functions': 'FunctionArn'}


def import_account_lambda_region_to_db(db: Session, import_job_id: int,
                                       region: str,
                                       proxy_builder: ProxyBuilder):
  job: ImportJob = db.query(ImportJob).get(import_job_id)
  writer = db_import_writer(db, job.id, 'lambda', phase=0, source='base')
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


def _import_function(proxy: ServiceProxy, function: Dict):
  name = function['FunctionName']
  arn = function['FunctionArn']
  versions_resp = proxy.list('list_versions_by_function', FunctionName=name)
  if versions_resp is not None:
    versions = versions_resp[1]['Versions']
    for version in versions:
      version['ParentFunctionArn'] = arn
      yield 'FunctionVersion', version
  aliases_resp = proxy.list('list_aliases', FunctionName=name)
  if aliases_resp is not None:
    aliases = aliases_resp[1]['Aliases']
    for alias in aliases:
      alias['FunctionArn'] = arn
      yield 'Alias', alias


def _import_functions(proxy: ServiceProxy):
  functions_resp = proxy.list('list_functions')
  if functions_resp is not None:
    functions = functions_resp[1]['Functions']
    for function in functions:
      arn_for_tags = HAS_TAGS.get('list_functions')
      if arn_for_tags is not None:
        arn = function[arn_for_tags]
        tags_result = proxy.list('list_tags', Resource=arn)
        if tags_result is not None:
          function['Tags'] = tags_result[1].get('Tags', [])
      yield 'Function', function
      yield from _import_function(proxy, function)


def _import_lambda_region(
    proxy: ServiceProxy) -> Generator[Tuple[str, Any], None, None]:
  yield from _import_functions(proxy)
  # TODO: layers, event sources


def _async_proxy(ps: PathStack, proxy_builder_args, import_job_id: int,
                 region: str, config: Dict):
  db = import_session()
  proxy_builder = make_proxy_builder(*proxy_builder_args)
  boto = load_boto_session_from_config(config)
  proxy = proxy_builder(boto)
  writer = db_import_writer(db,
                            import_job_id,
                            'lambda',
                            phase=0,
                            source='base')
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