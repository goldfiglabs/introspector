import concurrent.futures as f
import contextlib
from dataclasses import dataclass
from introspector.error import GFInternal
import logging
from typing import Any, Callable, ContextManager, Dict, Iterator, List, Optional, Tuple, Union

from sqlalchemy.orm import Session

from introspector import ImportWriter, db_import_writer, PathStack
from introspector.aws import (account_paths_for_import, load_boto_session,
                              load_boto_session_from_config)
from introspector.aws.fetch import ServiceProxy, Proxy
from introspector.bootstrap_db import import_session
from introspector.models import ImportJob, ProviderCredential

_log = logging.getLogger(__name__)

# empty list -> import everything
ServiceSpec = List[str]
ImportSpec = Optional[Dict[str, ServiceSpec]]


def parse_import_spec(config: Optional[str]) -> ImportSpec:
  if config is None:
    return None
  spec = {}
  for service_spec in config.split(';'):
    parts = service_spec.split('=')
    svc = parts[0]
    if len(parts) == 1:
      resources = []
    else:
      resources = parts[1].split(',')
    spec[svc] = resources
  return spec


def service_gate(spec: ImportSpec) -> Callable[[str], Optional[ServiceSpec]]:
  def gate(service: str) -> Optional[ServiceSpec]:
    if spec is None:
      return []
    else:
      resources = spec.get(service)
      if resources is not None:
        return resources
      else:
        _log.debug(f'Skipped service {service}')
        return None

  return gate


def resource_gate(spec: ServiceSpec, resource_name: str) -> bool:
  return len(spec) == 0 or resource_name in spec


RegionalImportFn = Callable[[ServiceProxy, str, ServiceSpec],
                            Iterator[Tuple[str, List[Any]]]]

RegionalDbImportFn = Callable[[Session, int, str, ServiceSpec], None]

Accounts = List[Tuple[str, ProviderCredential]]
RegionalPoolImportFn = Callable[
    [f.ProcessPoolExecutor, int, int, str, PathStack, Accounts, ServiceSpec],
    List[f.Future]]

GlobalImportFn = Callable[[ServiceProxy, ServiceSpec], Iterator[Tuple[str,
                                                                      Any]]]


@dataclass
class GlobalResourceSpec:
  fn: GlobalImportFn
  writer_transform: Optional[Callable[[ImportWriter], ImportWriter]] = None

  def __call__(self, proxy: ServiceProxy, base_writer: ImportWriter,
               account_id: str, ps: PathStack, service_spec: ServiceSpec):
    writer = base_writer if self.writer_transform is None else self.writer_transform(
        base_writer)
    for resource_name, raw_resource in self.fn(proxy, service_spec):
      writer(ps, resource_name, raw_resource, {'account_id': account_id})


GlobalResourceFn = Union[GlobalResourceSpec, GlobalImportFn]

GlobalPoolImportFn = Callable[
    [f.ProcessPoolExecutor, int, int, PathStack, Accounts, ServiceSpec],
    List[f.Future]]

GlobalDbImportFn = Callable[[Session, int, ServiceSpec], None]


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
    def import_to_db(db: Session, import_job_id: int,
                     service_spec: ServiceSpec):
      job = db.query(ImportJob).get(import_job_id)
      if job is None:
        raise GFInternal('Lost ImportJob')
      writer = db_import_writer(db,
                                job.id,
                                job.provider_account_id,
                                self.name,
                                phase=0,
                                source='base')
      for path, account in account_paths_for_import(db, job):
        boto = load_boto_session(account)
        proxy = Proxy.build(boto)
        ps = PathStack.from_import_job(job)
        service_proxy = proxy.service(self.name)
        for fn in resource_fns:
          fn(service_proxy, writer, account.scope, ps, service_spec)

    return import_to_db

  def _make_global_import_with_pool(
      self, resource_fns: List[GlobalResourceSpec]) -> GlobalPoolImportFn:
    def import_with_pool(pool: f.ProcessPoolExecutor, import_job_id: int,
                         provider_account_id: int, ps: PathStack,
                         accounts: List[Tuple[str, ProviderCredential]],
                         service_spec: ServiceSpec) -> List[f.Future]:
      results: List[f.Future] = []
      for path, account in accounts:
        for fn in resource_fns:
          future = pool.submit(_global_async_proxy,
                               ps=ps.scope(account.scope),
                               import_job_id=import_job_id,
                               provider_account_id=provider_account_id,
                               config=account.config,
                               svc_name=self.name,
                               account_id=account.scope,
                               service_spec=service_spec,
                               import_fn=fn)
          results.append(future)
      return results

    return import_with_pool


def make_import_to_db(svc_name: str,
                      fn: RegionalImportFn) -> RegionalDbImportFn:
  def import_region_to_db(db: Session, import_job_id: int, region: str,
                          service_spec: ServiceSpec):
    job = db.query(ImportJob).get(import_job_id)
    if job is None:
      raise GFInternal('Lost ImportJob')
    writer = db_import_writer(db,
                              job.id,
                              job.provider_account_id,
                              svc_name,
                              phase=0,
                              source='base')
    for path, account in account_paths_for_import(db, job):
      boto = load_boto_session(account)
      proxy = Proxy.build(boto)
      ps = PathStack.from_import_job(job).scope(account.scope)
      service_proxy = proxy.service(svc_name, region)
      ps = ps.scope(region)
      for resource_name, raw_resources in fn(service_proxy, region,
                                             service_spec):
        writer(ps, resource_name, raw_resources, {'region': region})

  return import_region_to_db


def _async_proxy(ps: PathStack, import_job_id: int, provider_account_id: int,
                 region: str, config: Dict, svc_name: str,
                 service_spec: ServiceSpec, import_fn: RegionalImportFn):
  db = import_session()
  ps = ps.scope(region)
  boto = load_boto_session_from_config(config)
  proxy = Proxy.build(boto)
  service_proxy = proxy.service(svc_name, region)
  writer = db_import_writer(db,
                            import_job_id,
                            provider_account_id,
                            svc_name,
                            phase=0,
                            source='base')
  _log.debug(f'Starting {svc_name} - {region}')
  for resource_name, raw_resources in import_fn(service_proxy, region,
                                                service_spec):
    writer(ps, resource_name, raw_resources, {'region': region})
  db.commit()
  _log.debug(f'Committed {svc_name} - {region}')


def make_import_with_pool(svc_name: str,
                          fn: RegionalImportFn) -> RegionalPoolImportFn:
  def import_region_with_pool(pool: f.ProcessPoolExecutor, import_job_id: int,
                              provider_account_id, region: str, ps: PathStack,
                              accounts: List[Tuple[str, ProviderCredential]],
                              service_spec: ServiceSpec) -> List[f.Future]:
    results: List[f.Future] = []

    for path, account in accounts:
      future = pool.submit(_async_proxy,
                           import_job_id=import_job_id,
                           provider_account_id=provider_account_id,
                           region=region,
                           ps=ps.scope(account.scope),
                           config=account.config,
                           svc_name=svc_name,
                           service_spec=service_spec,
                           import_fn=fn)
      results.append(future)
    return results

  return import_region_with_pool


def _global_async_proxy(ps: PathStack, import_job_id: int,
                        provider_account_id: int, config: Dict, svc_name: str,
                        account_id: str, service_spec: ServiceSpec,
                        import_fn: GlobalResourceSpec):
  db = import_session()
  boto = load_boto_session_from_config(config)
  proxy = Proxy.build(boto)
  service_proxy = proxy.service(svc_name)
  writer = db_import_writer(db,
                            import_job_id,
                            provider_account_id,
                            svc_name,
                            phase=0,
                            source='base')
  try:
    import_fn(service_proxy, writer, account_id, ps, service_spec)
  except Exception as e:
    _log.error(f'Failed for svc {svc_name}', exc_info=e)
    raise
  db.commit()
