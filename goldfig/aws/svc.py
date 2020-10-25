import concurrent.futures as f
from typing import Any, Callable, Dict, Iterator, List, Tuple

from sqlalchemy.orm import Session

from goldfig import db_import_writer, PathStack
from goldfig.aws import (account_paths_for_import, load_boto_session,
                         load_boto_session_from_config)
from goldfig.aws.fetch import ServiceProxy, Proxy
from goldfig.bootstrap_db import import_session
from goldfig.models import ImportJob, ProviderCredential

RegionalImportFn = Callable[[ServiceProxy, str], Iterator[Tuple[str,
                                                                List[Any]]]]

RegionalDbImportFn = Callable[[Session, int, str], None]

Accounts = List[Tuple[str, ProviderCredential]]
RegionalPoolImportFn = Callable[
    [f.ProcessPoolExecutor, int, str, PathStack, Accounts], List[f.Future]]

GlobalResourceFn = Callable[[ServiceProxy], Iterator[Tuple[str, Any]]]

GlobalPoolImportFn = Callable[
    [f.ProcessPoolExecutor, int, PathStack, Accounts], List[f.Future]]


def make_import_to_db(svc_name: str,
                      fn: RegionalImportFn) -> RegionalDbImportFn:
  def import_region_to_db(db: Session, import_job_id: int, region: str):
    job: ImportJob = db.query(ImportJob).get(import_job_id)
    writer = db_import_writer(db, job.id, svc_name, phase=0, source='base')
    for path, account in account_paths_for_import(db, job):
      boto = load_boto_session(account)
      proxy = Proxy.build(boto)
      ps = PathStack.from_import_job(job).scope(path)
      service_proxy = proxy.service(svc_name, region)
      ps = ps.scope(region)
      for resource_name, raw_resources in fn(service_proxy, region):
        writer(ps, resource_name, raw_resources, {'region': region})

  return import_region_to_db


def make_global_import_to_db(svc_name: str,
                             resource_fns: List[GlobalResourceFn]):
  def import_to_db(db: Session, import_job_id: int):
    job: ImportJob = db.query(ImportJob).get(import_job_id)
    writer = db_import_writer(db, job.id, svc_name, phase=0, source='base')
    for path, account in account_paths_for_import(db, job):
      boto = load_boto_session(account)
      proxy = Proxy.build(boto)
      ps = PathStack.from_import_job(job).scope(path)
      service_proxy = proxy.service(svc_name)
      for fn in resource_fns:
        for resource_name, raw_resource in fn(service_proxy):
          writer(ps, resource_name, raw_resource)

  return import_to_db


def _async_proxy(ps: PathStack, import_job_id: int, region: str, config: Dict,
                 svc_name: str, import_fn: RegionalImportFn):
  db = import_session()
  ps = ps.scope(region)
  boto = load_boto_session_from_config(config)
  proxy = Proxy.build(boto)
  service_proxy = proxy.service(svc_name, region)
  writer = db_import_writer(db,
                            import_job_id,
                            svc_name,
                            phase=0,
                            source='base')
  for resource_name, raw_resources in import_fn(service_proxy, region):
    writer(ps, resource_name, raw_resources, {'region': region})
  db.commit()


def make_import_with_pool(svc_name: str,
                          fn: RegionalImportFn) -> RegionalPoolImportFn:
  def import_region_with_pool(
      pool: f.ProcessPoolExecutor, import_job_id: int, region: str,
      ps: PathStack,
      accounts: List[Tuple[str, ProviderCredential]]) -> List[f.Future]:
    results: List[f.Future] = []

    for path, account in accounts:
      future = pool.submit(_async_proxy,
                           import_job_id=import_job_id,
                           region=region,
                           ps=ps.scope(path),
                           config=account.config,
                           svc_name=svc_name,
                           import_fn=fn)
      results.append(future)
    return results

  return import_region_with_pool


def _global_async_proxy(ps: PathStack, import_job_id: int, config: Dict,
                        svc_name: str, import_fn: GlobalResourceFn):
  db = import_session()
  boto = load_boto_session_from_config(config)
  proxy = Proxy.build(boto)
  service_proxy = proxy.service(svc_name)
  writer = db_import_writer(db,
                            import_job_id,
                            svc_name,
                            phase=0,
                            source='base')
  for resource_name, raw_resources in import_fn(service_proxy):
    writer(ps, resource_name, raw_resources)
  db.commit()


def make_global_import_with_pool(
    svc_name: str, resource_fns: List[GlobalResourceFn]) -> GlobalPoolImportFn:
  def import_with_pool(
      pool: f.ProcessPoolExecutor, import_job_id: int, ps: PathStack,
      accounts: List[Tuple[str, ProviderCredential]]) -> List[f.Future]:
    results: List[f.Future] = []
    for path, account in accounts:
      for fn in resource_fns:
        future = pool.submit(_global_async_proxy,
                             ps=ps.scope(path),
                             import_job_id=import_job_id,
                             config=account.config,
                             svc_name=svc_name,
                             import_fn=fn)
        results.append(future)

    return results

  return import_with_pool