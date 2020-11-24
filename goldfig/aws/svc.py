import concurrent.futures as f
from dataclasses import dataclass
import logging
from typing import Any, Callable, Dict, Iterator, List, Optional, Tuple, Union

from sqlalchemy.orm import Session

from goldfig import ImportWriter, db_import_writer, PathStack
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

GlobalImportFn = Callable[[ServiceProxy], Iterator[Tuple[str, Any]]]


@dataclass
class GlobalResourceSpec:
  fn: GlobalImportFn
  writer_transform: Optional[Callable[[ImportWriter], ImportWriter]] = None

  def __call__(self, proxy: ServiceProxy, base_writer: ImportWriter,
               account_id: str, ps: PathStack):
    writer = base_writer if self.writer_transform is None else self.writer_transform(
        base_writer)
    for resource_name, raw_resource in self.fn(proxy):
      writer(ps, resource_name, raw_resource, {'account_id': account_id})


GlobalResourceFn = Union[GlobalResourceSpec, GlobalImportFn]

GlobalPoolImportFn = Callable[
    [f.ProcessPoolExecutor, int, PathStack, Accounts], List[f.Future]]

GlobalDbImportFn = Callable[[Session, int], None]

_log = logging.getLogger(__name__)


class RegionalService:
  is_regional = True

  def __init__(self, name: str, fn: RegionalImportFn):
    self._fn = fn
    self.name = name

  def pool_fn(self) -> RegionalPoolImportFn:
    return make_import_with_pool(self.name, self._fn)

  def db_fn(self) -> RegionalDbImportFn:
    return make_import_to_db(self.name, self._fn)


class GlobalService:
  is_regional = False

  def __init__(self, name: str, fn: Union[GlobalResourceFn,
                                          List[GlobalResourceFn]]):
    self._fn = fn
    self.name = name

  def _fns(self) -> List[GlobalResourceSpec]:
    return [
        fn if isinstance(fn, GlobalResourceSpec) else GlobalResourceSpec(fn)
        for fn in (self._fn if isinstance(self._fn, list) else [self._fn])
    ]

  def pool_fn(self) -> GlobalPoolImportFn:
    return self._make_global_import_with_pool(self._fns())

  def db_fn(self) -> GlobalDbImportFn:
    return self._make_global_import_to_db(self._fns())

  def _make_global_import_to_db(
      self, resource_fns: List[GlobalResourceSpec]) -> GlobalDbImportFn:
    def import_to_db(db: Session, import_job_id: int):
      job: ImportJob = db.query(ImportJob).get(import_job_id)
      writer = db_import_writer(db, job.id, self.name, phase=0, source='base')
      for path, account in account_paths_for_import(db, job):
        boto = load_boto_session(account)
        proxy = Proxy.build(boto)
        ps = PathStack.from_import_job(job).scope(path)
        service_proxy = proxy.service(self.name)
        for fn in resource_fns:
          fn(service_proxy, writer, account.scope, ps)

    return import_to_db

  def _make_global_import_with_pool(
      self, resource_fns: List[GlobalResourceSpec]) -> GlobalPoolImportFn:
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
                               svc_name=self.name,
                               account_id=account.scope,
                               import_fn=fn)
          results.append(future)

      return results

    return import_with_pool


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
                        svc_name: str, account_id: str,
                        import_fn: GlobalResourceSpec):
  db = import_session()
  boto = load_boto_session_from_config(config)
  proxy = Proxy.build(boto)
  service_proxy = proxy.service(svc_name)
  writer = db_import_writer(db,
                            import_job_id,
                            svc_name,
                            phase=0,
                            source='base')
  try:
    import_fn(service_proxy, writer, account_id, ps)
  except Exception as e:
    _log.error(f'Failed for svc {svc_name}', exc_info=e)
    raise
  db.commit()
