import json
import logging
import os
from pathlib import Path
from typing import Any, Callable, Dict, Generator, Iterator, List, Optional, Tuple
import yaml

import botocore.exceptions
from botocore.session import Session as Boto

import jsonpatch

from goldfig.error import GFInternal

_log = logging.getLogger(__name__)

_THIS_DIR: Path = Path(os.path.dirname(__file__))
KeyFilter = Callable[[str], bool]


class Cache(object):
  _DEFAULT_CACHE = _THIS_DIR.parent.parent / 'cache' / 'aws' / '1'

  @classmethod
  def default(cls) -> 'Cache':
    return cls(path=cls._DEFAULT_CACHE, update_on_miss=True)

  @classmethod
  def patched(cls, patch_id: int) -> 'Cache':
    patch_dir = _THIS_DIR.parent.parent / 'patches' / 'aws' / str(patch_id)
    return cls(path=cls._DEFAULT_CACHE,
               update_on_miss=False,
               patch_dir=str(patch_dir))

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

  def client(self, service: str, region: Optional[str]) -> 'ClientCache':
    patch = None
    if self._patch_dir is not None:
      patch_path = Path(self._patch_dir) / f'{service}_{region}.json'
      if patch_path.exists():
        with open(str(patch_path), 'r') as f:
          patch = json.load(f)
      _log.debug(f'Using patch for {service} {patch}')
    filename = service if region is None else f'{service}_{region}'
    return ClientCache(self._path / f'{filename}.json',
                       self._update_on_miss,
                       patch=patch)


class ClientCache(object):
  def __init__(self, path: Path, update_on_miss: bool, patch=None):
    self._path = path
    self._update_on_miss = update_on_miss
    try:
      with open(str(self._path), 'r') as f:
        self._cached = json.load(f)
    except FileNotFoundError:
      self._cached = {}
    if patch is not None:
      _log.debug('patching')
      jsonpatch.apply_patch(self._cached, patch, in_place=True)

  def get(self, resource: str, kwargs) -> Optional[Any]:
    gets = self._cached.get('get', {}).get(resource, [])
    for get in gets:
      if get['args'] == kwargs:
        return get['result']
    return None

  def cache_get_result(self, resource: str, args, result):
    if not self._update_on_miss:
      return
    gets = self._cached.get('get')
    if gets is None:
      gets = {}
      self._cached['get'] = gets
    resource_gets = gets.get(resource, [])
    resource_gets.append({'args': args, 'result': result})
    gets[resource] = resource_gets
    with open(str(self._path), 'w') as f:
      json.dump(self._cached, f)

  def list(self, resource: str, kwargs) -> Optional[Any]:
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


class ClientProxy(object):
  def __init__(self, client):
    self._client = client
    self._patch_client()

  def _patch_client(self):
    pass

  def _should_import(self, key: str) -> bool:
    return True

  def resource_names(self) -> Iterator[str]:
    return filter(self._should_import, dir(self._client))

  def _list_args(self, key: str) -> Dict:
    return {}

  def _paginate_args(self, key: str) -> Dict:
    return {}

  def canonical_name(self, py_name: str) -> str:
    return self._client.meta.method_to_api_mapping[py_name]

  def _map_error_code(self, code: str, resource_name: str) -> Optional[str]:
    return None

  def list(self, key: str, kwargs) -> Optional[Tuple[str, Any]]:
    prefix = len(key.split('_')[0])
    resource_name = self._client._PY_TO_OP_NAME[key][prefix:]
    extra_kwargs = dict(self._list_args(key), **kwargs)
    try:
      if self._client.can_paginate(key):
        paginator = self._client.get_paginator(key)
        method_args = dict(self._paginate_args(key), **extra_kwargs)
        iterator = paginator.paginate(**method_args)
        result = iterator.build_full_result()
      else:
        op = self._client.meta.method_to_api_mapping[key]
        op_model = self._client.meta.service_model.operation_model(op)
        output = op_model.output_shape
        attr = getattr(self._client, key)
        full_result = attr(**extra_kwargs)
        result = {
            result_key: full_result[result_key]
            for result_key in output.members.keys()
            if result_key in full_result
        }
      return resource_name, result
    except KeyError as e:
      raise GFInternal(
          f'Pagination Exception raise {self._client._PY_TO_OP_NAME[key]}')
    except botocore.exceptions.ParamValidationError as e:
      # TODO: fix this
      _log.debug(f'{key} Needs param input {str(e)}')
      return resource_name, {'goldfig': 'needs param input'}
    except botocore.exceptions.ClientError as e:
      code = e.response.get('Error', {}).get('Code')
      if code == 'UnsupportedOperation':
        _log.info(f'{resource_name} Not supported in this region')
        return resource_name, {'goldfig': 'unsupported in region'}
      elif code == 'UnauthorizedOperation':
        return resource_name, {'goldfig': 'unauthorized'}
      elif code == 'MissingParameter':
        return resource_name, {'goldfig': 'missing parameter'}
      elif code == 'OptInRequired':
        return resource_name, {'goldfig': 'missing opt-in'}
      elif code == 'AuthFailure':
        return resource_name, {'goldfig': 'auth failure'}
      elif code == 'InvalidClientTokenId':
        return resource_name, {'goldfig': 'invalid token'}
      elif code == 'NoSuchEntity':
        # No results, return nothing
        return None
      else:
        mapped = self._map_error_code(code, resource_name)
        if mapped is not None:
          return resource_name, {'goldfig': mapped}
        raise e

  def get(self, key: str, kwargs):
    try:
      api_call = getattr(self._client, key)
      full_result = api_call(**kwargs)
      op = self._client.meta.method_to_api_mapping[key]
      op_model = self._client.meta.service_model.operation_model(op)
      output = op_model.output_shape
      attr_result = {}
      saw_result = False
      for result_key in output.members.keys():
        value = full_result.get(result_key)
        if value is not None:
          saw_result = True
          attr_result[result_key] = value
      if saw_result:
        return attr_result
    except botocore.exceptions.ClientError as e:
      error = e.response.get('Error', {}).get('Code', '')
      if error.startswith('NoSuch') or error.endswith('NotFoundError'):
        # No results, nothing to return
        pass
      else:
        raise e


class EC2ClientProxy(ClientProxy):
  MISSING_PAGINATION = {
      'describe_coip_pools':
      'PoolIds',
      'describe_elastic_gpus':
      'ElasticGpuSet',
      'describe_instance_type_offerings':
      'InstanceTypeOfferings',
      'describe_local_gateway_route_table_virtual_interface_group_associations':
      'LocalGatewayRouteTableVirtualInterfaceGroupAssociationIds',
      'describe_local_gateway_route_table_vpc_associations':
      'LocalGatewayRouteTableVpcAssociations',
      'describe_local_gateway_route_tables':
      'LocalGatewayRouteTableSet',
      'describe_local_gateway_virtual_interface_groups':
      'LocalGatewayVirtualInterfaceGroups',
      'describe_local_gateway_virtual_interfaces':
      'LocalGatewayVirtualInterfaces',
      'describe_local_gateways':
      'LocalGateways',
      'describe_transit_gateway_peering_attachments':
      'TransitGatewayPeeringAttachments',
      'describe_instance_types':
      'InstanceTypes',
      'describe_transit_gateway_multicast_domains':
      'TransitGatewayMulticastDomains'
  }

  SKIPLIST = [
      'describe_reserved_instances_offerings',
      'describe_spot_price_history',
      #'describe_images',  # TODO: re-enable with filter
      'describe_snapshots',  # TODO: re-enable with filter?
      # Describes services that *can* have VPC endpoints, not ones that do
      'describe_vpc_endpoint_services',
      # TODO: verify this, i think it's about regional support for long ids
      'describe_aggregate_id_format',
      # TODO: look into this
      'describe_moving_addresses',
      # Failing in some cases, and we don't map
      'describe_id_format'
  ]

  EXTRA_ARGS = {
      'describe_images': {
          'Filters': [{
              'Name': 'is-public',
              'Values': ['False']
          }]
      }
  }

  PAGE_SIZES = {
      'describe_ipv6_pools': 10,
      'describe_public_ipv4_pools': 10,
      'describe_reserved_instances_modifications': None
  }

  INVALID_ACTIONS = [
      'FpgaImages', 'TransitGatewayMulticastDomains', 'ByoipCidrs',
      'Ipv6Pools', 'CoipPools',
      'LocalGatewayRouteTableVirtualInterfaceGroupAssociations',
      'LocalGatewayRouteTableVpcAssociations', 'LocalGatewayRouteTables',
      'LocalGatewayVirtualInterfaceGroups', 'LocalGatewayVirtualInterfaces',
      'LocalGateways'
  ]

  def __init__(self, *args, **kwargs):
    super().__init__(*args, **kwargs)
    ec2_svc_file = _THIS_DIR / 'svcs' / 'ec2.yml'
    with ec2_svc_file.open('r') as f:
      self._spec = yaml.safe_load(f)

  def _patch_client(self):
    # Force loading of the pagination config
    self._client.can_paginate('describe_instances')
    assert 'page_config' in self._client._cache
    for py_name, result_key in self.MISSING_PAGINATION.items():
      op_name = self._client._PY_TO_OP_NAME[py_name]
      self._client._cache['page_config'][op_name] = {
          'input_token': 'NextToken',
          'output_token': 'NextToken',
          'limit_key': 'MaxResults',
          'result_key': result_key
      }

  def _should_import(self, key: str) -> bool:
    return key.startswith('describe_') and key not in self.SKIPLIST

  def _list_args(self, key: str) -> Dict:
    return self.EXTRA_ARGS.get(key, {})

  def _paginate_args(self, key: str) -> Dict:
    # TODO: key this off of output shape
    page_size = self.PAGE_SIZES.get(key, 100)
    return {'PaginationConfig': {'PageSize': page_size}}

  def _map_error_code(self, code: str, resource_name: str) -> Optional[str]:
    if code == 'InvalidSpotDatafeed.NotFound':
      return 'Missing subscription'
    elif code == 'InvalidAction' and resource_name in self.INVALID_ACTIONS:
      return 'Missing Input params'
    return None


class S3ClientProxy(ClientProxy):
  MISSING_PAGINATION = {
      'list_bucket_analytics_configurations': 'AnalyticsConfigurationList',
      'list_bucket_inventory_configurations': 'InventoryConfigurationList',
      'list_bucket_metrics_configurations': 'MetricsConfigurationList'
  }
  GET_PREFIX = 'get_bucket_'
  LIST_PREFIX = 'list_bucket_'

  def _patch_client(self):
    # Force loading of the pagination config
    self._client.can_paginate('list_bucket_analytics_configurations')
    for py_name, result_key in self.MISSING_PAGINATION.items():
      op_name = self._client._PY_TO_OP_NAME[py_name]
      self._client._cache['page_config'][op_name] = {
          'input_token': 'ContinuationToken',
          'output_token': 'NextContinuationToken',
          'result_key': result_key
      }

  def _should_import(self, key: str) -> bool:
    if key.startswith(self.LIST_PREFIX):
      return True
    elif key.startswith(self.GET_PREFIX):
      # Only return true if there is not a corresponding list call
      item = key[len(self.GET_PREFIX):]
      list_op = f'list_bucket_{item}s'
      return not hasattr(self._client, list_op)
    else:
      return False


class ELBClientProxy(ClientProxy):

  SKIPLIST = [
      'describe_load_balancers', 'describe_account_limits',
      'describe_instance_health', 'describe_load_balancer_policy_types'
  ]

  def _should_import(self, key: str) -> bool:
    return key.startswith('describe_') and key not in self.SKIPLIST


class LambdaClientProxy(ClientProxy):

  SKIPLIST: List[str] = []

  def _should_import(self, key: str) -> bool:
    return key.startswith('list_') and key not in self.SKIPLIST


class CloudtrailClientProxy(ClientProxy):

  SKIPLIST: List[str] = []

  def _should_import(self, key: str) -> bool:
    return key.startswith('describe_') and key not in self.SKIPLIST


class RDSClientProxy(ClientProxy):

  SKIPLIST = [
      'describe_custom_availability_zones',
      'describe_installation_media',
      'describe_export_tasks',
      'describe_reserved_db_instances_offerings',
      'describe_db_engine_versions',
      'describe_valid_db_instance_modifications',
      'describe_option_group_options',
      'describe_db_proxies',  # Not sure why this comes back with unknown
      'describe_global_clusters'
  ]

  def _should_import(self, key: str) -> bool:
    return key.startswith('describe_') and key not in self.SKIPLIST


class IAMClientProxy(ClientProxy):

  SKIPLIST: List[str] = []
  MISSING_PAGINATION = {'list_user_tags': 'Tags', 'list_role_tags': 'Tags'}

  def _should_import(self, key: str) -> bool:
    return key.startswith('list_') and key not in self.SKIPLIST

  def _patch_client(self):
    # Force loading of the pagination config
    self._client.can_paginate('list_users')
    for py_name, result_key in self.MISSING_PAGINATION.items():
      op_name = self._client._PY_TO_OP_NAME[py_name]
      self._client._cache['page_config'][op_name] = {
          'input_token': 'Marker',
          'limit_key': 'MaxItems',
          'more_results': 'IsTruncated',
          'output_token': 'Marker',
          'result_key': result_key
      }


class AWSFetch(object):
  SVC_CLASS = {
      'ec2': EC2ClientProxy,
      's3': S3ClientProxy,
      'elb': ELBClientProxy,
      'iam': IAMClientProxy,
      'rds': RDSClientProxy,
      'lambda': LambdaClientProxy,
      'cloudtrail': CloudtrailClientProxy
  }

  def __init__(self, boto: Boto):
    self._boto = boto

  def client(self,
             service: str,
             region: Optional[str] = None) -> 'ClientProxy':
    client_class = self.SVC_CLASS.get(service, ClientProxy)
    kwargs = {}
    if region is not None:
      kwargs['region_name'] = region
    client = self._boto.create_client(service, **kwargs)
    return client_class(client)


class ServiceProxy(object):
  def __init__(self, impl: ClientProxy, cache: ClientCache):
    self._impl = impl
    self._cache = cache

  def resource_names(self) -> Iterator[str]:
    return self._impl.resource_names()

  def list(self, resource: str, **kwargs) -> Optional[Tuple[str, Any]]:
    cached = self._cache.list(resource, kwargs)
    if cached is None:
      _log.info(f'cache miss list {resource} {kwargs}')
      result = self._impl.list(resource, kwargs)
      self._cache.cache_list_result(resource, kwargs, result)
      return result
    else:
      return cached

  def get(self, resource: str, **kwargs):
    cached = self._cache.get(resource, kwargs)
    if cached is None:
      _log.info(f'cache miss get {resource} {kwargs}')
      result = self._impl.get(resource, kwargs)
      self._cache.cache_get_result(resource, kwargs, result)
      return result
    else:
      return cached

  def canonical_name(self, py_name: str) -> str:
    return self._impl.canonical_name(py_name)


class Proxy(object):
  @classmethod
  def build(cls, boto: Boto, patch_id: Optional[int] = None) -> 'Proxy':
    if patch_id is not None:
      cache = Cache.patched(patch_id)
    else:
      cache = Cache.default()
    return cls(AWSFetch(boto), cache)

  @classmethod
  def dummy(cls, boto: Boto) -> 'Proxy':
    return cls(AWSFetch(boto), Cache.dummy())

  def __init__(self, aws: AWSFetch, cache: Cache):
    self._aws = aws
    self._cache = cache

  def service(self,
              service: str,
              region: Optional[str] = None) -> ServiceProxy:
    return ServiceProxy(self._aws.client(service, region),
                        self._cache.client(service, region))
