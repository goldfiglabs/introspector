from functools import partial
import json
import logging
import os
from pathlib import Path
from typing import Dict, List, Optional, Generator, Tuple, Any

# from google.oauth2 import credentials
from googleapiclient.discovery import build as build_raw
from googleapiclient.discovery_cache.base import Cache as GoogleCache

import jsonpatch

from goldfig.error import GFInternal
from goldfig.gcp.types import GcpCredentials

_THIS_DIR: Path = Path(os.path.dirname(__file__))

_log = logging.getLogger(__name__)


class _MemoryCache(GoogleCache):
  _CACHE = {}

  def get(self, url):
    return _MemoryCache._CACHE.get(url)

  def set(self, url, content):
    _MemoryCache._CACHE[url] = content


build = partial(build_raw, cache=_MemoryCache())


class Cache(object):
  _DEFAULT_CACHE = _THIS_DIR.parent.parent / 'cache' / 'gcp' / '1'

  @classmethod
  def default(cls) -> 'Cache':
    return cls(path=cls._DEFAULT_CACHE, update_on_miss=True)

  @classmethod
  def patched(cls, patch_id: int) -> 'Cache':
    patch_dir = _THIS_DIR.parent.parent / 'patches' / 'gcp' / str(patch_id)
    return cls(path=cls._DEFAULT_CACHE,
               update_on_miss=False,
               patch_dir=patch_dir)

  @classmethod
  def dummy(cls) -> 'Cache':
    return cls(Path('dummy'), update_on_miss=False)

  def __init__(self,
               path: Path,
               update_on_miss: bool,
               patch_dir: Optional[str] = None):
    self._path = path
    self._update_on_miss = update_on_miss
    self._patch_dir = patch_dir
    if self._update_on_miss:
      os.makedirs(str(self._path), exist_ok=True)

  def service(self, service: str, version: str) -> 'ServiceCache':
    patch = None
    if self._patch_dir is not None:
      patch_path = self._patch_dir / f'{service}_{version}.json'
      if patch_path.exists():
        with open(str(patch_path), 'r') as f:
          patch = json.load(f)
        _log.debug(f'Using patch for {service} {patch}')
    return ServiceCache(self._path / f'{service}_{version}.json',
                        self._update_on_miss,
                        patch=patch)


class ServiceCache(object):
  def __init__(self, path: Path, update_on_miss: bool, patch=None):
    _log.info(f'Using cache at {path}. Update: {update_on_miss}')
    self._path = path
    self._update_on_miss = update_on_miss
    try:
      with open(str(self._path), 'r') as f:
        self._cached: Dict[str, Any] = json.load(f)
    except FileNotFoundError:
      self._cached = {}
    if patch is not None:
      jsonpatch.apply_patch(self._cached, patch, in_place=True)

  def get(self, resource: str, kwargs):
    resources: List[Any] = self._cached.get('get', {}).get(resource, [])
    for resource in resources:
      if resource['args'] == kwargs:
        return resource['result']
    return None

  def call_method(self, resource: str, method: str, kwargs):
    resources = self._cached.get('method', {}).get(resource, [])
    for resource in resources:
      if resource['method'] == method and resource['args'] == kwargs:
        return resource['result']
    return None

  def cache_call_method_result(self, resource: str, method: str, args, result):
    if not self._update_on_miss:
      return
    methods = self._cached.get('method')
    if methods is None:
      methods = {}
      self._cached['method'] = methods
    resources = methods.get(resource, [])
    resources.append({'args': args, 'method': method, 'result': result})
    methods[resource] = resources
    with open(str(self._path), 'w') as f:
      json.dump(self._cached, f)

  def cache_get_result(self, resource: str, args, result):
    if not self._update_on_miss:
      return
    gets = self._cached.get('get')
    if gets is None:
      gets = {}
      self._cached['get'] = gets
    resources = gets.get(resource, [])
    resources.append({'args': args, 'result': result})
    gets[resource] = resources
    with open(str(self._path), 'w') as f:
      json.dump(self._cached, f)

  def list(self, resource: str, kwargs):
    resource_lists = self._cached.get('list', {}).get(resource, [])
    for resource_list in resource_lists:
      if resource_list['args'] == kwargs:
        return resource_list['result']
    return None

  def cache_list_result(self, resource: str, args, result):
    if not self._update_on_miss:
      return
    lists = self._cached.get('list')
    if lists is None:
      lists = {}
      self._cached['list'] = lists
    resource_lists = lists.get(resource, [])
    resource_lists.append({'args': args, 'result': result})
    lists[resource] = resource_lists
    with open(str(self._path), 'w') as f:
      json.dump(self._cached, f)


#ComputeList = Generator[Tuple[str, Any], None, None]
ComputeList = List[Tuple[str, Any]]


class _ComputeServiceWrapper(object):
  SKIPLIST = [
      'zones',
      'regions',
      'licenseCodes',
      'projects',
      # Operations-related stuff
      'globalOperations',
      'globalOrganizationOperations',
      'regionOperations',
      'zoneOperations',
      # TODO: add support for this
      'organizationSecurityPolicies'
  ]

  def __init__(self, service):
    self._service = service
    self._zone_names = {}
    self._region_names = {}

  def zone_names(self, project: str) -> List[str]:
    zones = self._zone_names.get(project, None)
    if zones is None:
      zones_resource = self._service.zones()
      zone_response = zones_resource.list(project=project).execute()
      zones = list(map(lambda zone: zone['name'], zone_response['items']))
      self._zone_names[project] = zones
    return zones

  def region_names(self, project: str) -> List[str]:
    region_names = self._region_names.get(project, None)
    if region_names is None:
      regions_resource = self._service.regions()
      region_result = regions_resource.list(project=project).execute()
      region_names = list(
          map(lambda region: region['name'], region_result['items']))
      self._region_names[project] = region_names
    return region_names

  def resource(self, resource_name: str):
    resource = getattr(self._service, resource_name)
    if not callable(resource):
      raise GFInternal(f'{resource_name} in GCP compute is not callabe')
    return resource()

  def _should_attempt_list(self, resource_name: str) -> bool:
    return resource_name not in self.SKIPLIST \
      and not resource_name.startswith('_') \
      and resource_name.endswith('s')

  def resource_names(self):
    return filter(lambda r: self._should_attempt_list(r), dir(self._service))

  def _is_regional(self, resource_name: str) -> bool:
    return resource_name.startswith('region')

  def _is_zonal(self, resource_name: str) -> bool:
    return resource_name.startswith('zone')

  def _aggregate_list(self, resource, resource_name: str, args) -> ComputeList:
    agg = resource.aggregatedList(**args).execute()
    results = []
    for zone, response in agg['items'].items():
      resources = response.get(resource_name, [])
      results.append((zone, resources))
    return results

  def _list_regional(self, regions: List[str], resource,
                     kwargs) -> ComputeList:
    results = []
    for region in regions:
      result = resource.list(region=region, **kwargs).execute()
      if region.startswith('regions/'):
        path = region
      else:
        path = f'regions/{region}'
      results.append((path, result.get('items', [])))
    return results

  def _list_zonal(self, zones: List[str], resource, kwargs) -> ComputeList:
    results = []
    for zone in zones:
      result = resource.list(zone=zone, **kwargs).execute()
      if zone.startswith('zones/'):
        path = zone
      else:
        path = f'zones/{zone}'
      results.append((path, result.get('items', [])))
    return results

  def _list_resource(self, resource, kwargs) -> ComputeList:
    result = resource.list(**kwargs).execute()
    return [('', result.get('items', []))]

  def get(self, resource: str, kwargs):
    su = self.resource(resource)
    return su.get(**kwargs).execute()

  def list(self, resource_name: str, kwargs) -> ComputeList:
    resource = self.resource(resource_name)
    methods = dir(resource)
    if 'aggregatedList' in methods:
      _log.debug(f'aggregate: {resource_name}')
      yield self._aggregate_list(resource, resource_name, kwargs)
    elif 'list' in methods:
      if self._is_regional(resource_name):
        _log.debug(f'regional: {resource_name}')
        yield self._list_regional(self.region_names(kwargs['project']),
                                  resource, kwargs)
      elif self._is_zonal(resource_name):
        _log.debug(f'zonal: {resource_name}')
        yield self._list_zonal(self.zone_names(kwargs['project']), resource,
                               kwargs)
      else:
        _log.debug(f'global: {resource_name}')
        yield self._list_resource(resource, kwargs)
    else:
      raise GFInternal(f'not listable: {resource_name}')


class GCPServiceFetch(object):
  def __init__(self, service):
    self._service = service

  def get(self, resource: str, kwargs):
    su = getattr(self._service, resource)()
    return su.get(**kwargs).execute()

  def _should_attempt_list(self, resource_name: str) -> bool:
    return not resource_name.startswith('_') \
      and resource_name.endswith('s')

  def resource_names(self):
    return filter(lambda r: self._should_attempt_list(r), dir(self._service))

  def resource(self, resource_name: str):
    current = self._service
    for token in resource_name.split('/'):
      resource = getattr(current, token)
      if not callable(resource):
        raise GFInternal(f'GCP {resource_name} is not callabe')
      current = resource()
    return current

  def _list_result_key(self, resource_name: str) -> str:
    return 'items'

  def list(self, resource_name: str, kwargs) -> Generator[Any, None, None]:
    resource = self.resource(resource_name)
    if hasattr(resource, 'list'):
      results = []
      paginate = hasattr(resource, 'list_next')
      req = resource.list(**kwargs)
      result_key = self._list_result_key(resource_name)
      _log.debug(f'Using result key {result_key}')
      while req is not None:
        resp = req.execute()
        _log.debug(f'response {resp}')
        results.extend(resp.get(result_key, []))
        req = resource.list_next(req, resp) if paginate else None
      yield results
    else:
      raise GFInternal(f'Resource {resource_name} has no method "list"')

  def call_method(self, resource_name: str, method_name: str, kwargs):
    resource = self.resource(resource_name)
    method = getattr(resource, method_name)
    return method(**kwargs).execute()


class _IamServiceWrapper(GCPServiceFetch):
  def _list_result_key(self, resource_name: str) -> str:
    if resource_name.endswith('/roles'):
      return 'roles'
    elif resource_name.endswith('/serviceAccounts'):
      return 'accounts'
    return super()._list_result_key(resource_name)


class _CloudResourceManagerWRapper(GCPServiceFetch):
  def _list_result_key(self, resource_name: str) -> str:
    return resource_name


class GCPFetch(object):
  CUSTOM = {
      'compute': _ComputeServiceWrapper,
      'iam': _IamServiceWrapper,
      'cloudresourcemanager': _CloudResourceManagerWRapper
  }

  def __init__(self, creds: GcpCredentials):
    self._credentials = creds

  def service(self, service: str, version: str) -> 'GCPServiceFetch':
    su = build(service, version, credentials=self._credentials)
    impl = self.CUSTOM.get(service, None)
    if impl is None:
      impl = GCPServiceFetch
    return impl(su)


class Proxy(object):
  @classmethod
  def build(cls, creds: GcpCredentials, patch_id: Optional[int]) -> 'Proxy':
    if patch_id is not None:
      cache = Cache.patched(patch_id)
    else:
      cache = Cache.default()
    return cls(GCPFetch(creds), cache)

  @classmethod
  def dummy(cls, creds: GcpCredentials) -> 'Proxy':
    cache = Cache.dummy()
    return cls(GCPFetch(creds), cache)

  # TODO: consider embedding the principal here?
  def __init__(self, gcp: GCPFetch, cache: Cache):
    self._gcp = gcp
    self._cache = cache

  def service(self, name: str, version: str) -> 'ServiceProxy':
    return ServiceProxy(self._gcp.service(name, version),
                        self._cache.service(name, version))


class ServiceProxy(object):
  def __init__(self, service_impl, cache: ServiceCache):
    self._impl = service_impl
    self._cache = cache

  def get(self, resource: str, **kwargs):
    cached = self._cache.get(resource, kwargs)
    if cached is None:
      _log.debug(f'cache miss {resource}, {kwargs}')
      result = self._impl.get(resource, kwargs)
      self._cache.cache_get_result(resource, kwargs, result)
      return result
    else:
      return cached

  def resource_names(self):
    return self._impl.resource_names()

  def list(self, resource: str, **kwargs) -> List[Any]:
    cached = self._cache.list(resource, kwargs)
    if cached is None:
      _log.debug(f'cache miss list {resource} {kwargs}')
      result = next(self._impl.list(resource, kwargs))
      self._cache.cache_list_result(resource, kwargs, result)
      return result
    else:
      return cached

  def call_method(self, resource_name: str, method: str, **kwargs):
    cached = self._cache.call_method(resource_name, method, kwargs)
    if cached is None:
      _log.debug(f'cache miss call_method {resource_name}, {method}, {kwargs}')
      result = self._impl.call_method(resource_name, method, kwargs)
      self._cache.cache_call_method_result(resource_name, method, kwargs,
                                           result)
      return result
    else:
      return cached
