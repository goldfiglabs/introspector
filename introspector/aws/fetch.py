import logging
import os
from pathlib import Path
from typing import Any, Callable, Dict, Iterator, List, Optional, Tuple
import yaml

import botocore.exceptions
from botocore.session import Session as Boto

from introspector.error import GFInternal
from introspector.models.raw_import import ERROR_KEY

_log = logging.getLogger(__name__)

_THIS_DIR: Path = Path(os.path.dirname(__file__))
KeyFilter = Callable[[str], bool]


class ClientProxy(object):
  def __init__(self, client):
    self._client = client
    self._patch_client()

  @property
  def _is_gov(self) -> bool:
    return '-gov-' in self._client.meta.region_name

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
      return resource_name, {ERROR_KEY: 'needs param input'}
    except botocore.exceptions.ClientError as e:
      code = e.response.get('Error', {}).get('Code')
      if code == 'UnsupportedOperation':
        _log.info(f'{resource_name} Not supported in this region')
        return resource_name, {ERROR_KEY: 'unsupported in region'}
      elif code == 'UnauthorizedOperation':
        return resource_name, {ERROR_KEY: 'unauthorized'}
      elif code == 'MissingParameter':
        return resource_name, {ERROR_KEY: 'missing parameter'}
      elif code == 'OptInRequired':
        return resource_name, {ERROR_KEY: 'missing opt-in'}
      elif code == 'AuthFailure':
        return resource_name, {ERROR_KEY: 'auth failure'}
      elif code == 'InvalidClientTokenId':
        return resource_name, {ERROR_KEY: 'invalid token'}
      elif code == 'NoSuchEntity':
        # No results, return nothing
        return None
      else:
        mapped = self._map_error_code(code, resource_name)
        if mapped is not None:
          return resource_name, {ERROR_KEY: mapped}
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
      # unsupported
      'describe_transit_gateway_connect_peers',
      'describe_transit_gateway_connects',
      'describe_spot_price_history',
      # Describes services that *can* have VPC endpoints, not ones that do
      'describe_vpc_endpoint_services',
      # TODO: verify this, i think it's about regional support for long ids
      'describe_aggregate_id_format',
      # TODO: look into this
      'describe_moving_addresses',
      # Failing in some cases, and we don't map
      'describe_id_format',
      # not needed, it's on most return values
      'describe_tags',
      # Not top level
      'describe_instance_attribute'
  ]

  GOV_SKIPLIST = [
      'describe_client_vpn_endpoints', 'describe_managed_prefix_lists',
      'describe_network_insights_analyses', 'describe_network_insights_paths'
  ]

  EXTRA_ARGS = {
      'describe_images': {
          'Filters': [{
              'Name': 'is-public',
              'Values': ['False']
          }]
      },
      'describe_snapshots': {
          'OwnerIds': ['self']
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
    return key.startswith('describe_') and key not in self.SKIPLIST and not (
        self._is_gov and key in self.GOV_SKIPLIST)

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
  SKIPLIST = [
      # deprecated methods covered by other calls
      'get_bucket_notification',
      'get_bucket_lifecycle',
      'list_bucket_intelligent_tiering_configurations'
  ]
  GOV_SKIPLIST = ['get_bucket_accelerate_configuration']

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
    if key in self.SKIPLIST:
      return False
    elif self._is_gov and key in self.GOV_SKIPLIST:
      return False
    elif key.startswith(self.LIST_PREFIX):
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
      'describe_global_clusters',
      # migrating away
      'describe_db_snapshots',
      'describe_db_cluster_snapshots'
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
  def __init__(self, impl: ClientProxy):
    self._impl = impl

  def resource_names(self) -> Iterator[str]:
    return self._impl.resource_names()

  def list(self, resource: str, **kwargs) -> Optional[Tuple[str, Any]]:
    _log.info(f'calling list {resource} {kwargs}')
    return self._impl.list(resource, kwargs)

  def get(self, resource: str, **kwargs):
    _log.info(f'calling get {resource} {kwargs}')
    return self._impl.get(resource, kwargs)

  def canonical_name(self, py_name: str) -> str:
    return self._impl.canonical_name(py_name)


class Proxy(object):
  @classmethod
  def build(cls, boto: Boto, patch_id: Optional[int] = None) -> 'Proxy':
    return cls(AWSFetch(boto))

  @classmethod
  def dummy(cls, boto: Boto) -> 'Proxy':
    return cls(AWSFetch(boto))

  def __init__(self, aws: AWSFetch):
    self._aws = aws

  def service(self,
              service: str,
              region: Optional[str] = None) -> ServiceProxy:
    return ServiceProxy(self._aws.client(service, region))
