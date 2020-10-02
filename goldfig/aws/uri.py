from functools import partial
from typing import Dict, Optional

from goldfig.error import GFError, GFInternal


def _iam_uri_fn(resource_name, **kwargs):
  if resource_name == 'policy-version':
    return f'{kwargs["policy_arn"]}:{kwargs["version_id"]}'
  elif resource_name in ('RolePolicy', 'UserPolicy', 'GroupPolicy'):
    return f'{kwargs["arn"]}:{kwargs["policy_name"]}'
  elif resource_name == 'PasswordPolicy':
    account_id = _get_with_parent('account_id', kwargs)
    return f'{account_id}/PasswordPolicy'
  raise GFInternal(f'Failed IAM ARN ({resource_name}) {kwargs}')


def _listener_arn_fn(loadbalancer_name, listener_id, account, region,
                     partition) -> str:
  # Load balancer id?
  return f'arn:{partition}:elasticloadbalancing:' \
    f'{region}:{account}:listener/{loadbalancer_name}/' \
    f'{listener_id}'


def _elb_arn_fn(resource_name: str, partition: str, account_id: str,
                **kwargs) -> str:
  region = kwargs['context']['region']
  if resource_name == 'loadbalancer':
    name = kwargs['name']
    return f'arn:{partition}:elasticloadbalancing:' \
      f'{region}:{account_id}:loadbalancer/{name}'
  elif resource_name == 'Listener':
    return _listener_arn_fn(kwargs['loadbalancer_name'], kwargs['listener_id'],
                            account_id, region, partition)
  raise GFInternal(f'Failed ELB ARN {resource_name} {kwargs}')


def _zone_to_region(zone: str) -> str:
  return zone[:-1]


def _s3_bucket_arn_fn(name: str, partition: str) -> str:
  return f'arn:{partition}:s3:::{name}'


def _get_with_parent(key: str, args: Dict) -> Optional[str]:
  val = args.get(key)
  if val is not None:
    return val
  parent_args = args.get('parent_uri', {})
  val = parent_args.get(key)
  if val is not None:
    return val
  context = args.get('context')
  if context is not None:
    return context.get(key)
  return None


def _ec2_arn_fn(resource_name, account, partition, **kwargs) -> str:
  id = kwargs['id']
  region = _get_with_parent('region', kwargs)
  if region is None:
    zone = _get_with_parent('zone', kwargs)
    if zone is not None:
      region = _zone_to_region(zone)
  if region is None:
    raise GFInternal(f'Missing region in {kwargs}')
  return f'arn:{partition}:ec2:{region}:{account}:{resource_name.lower()}/{id}'


def _logs_uri_fn(partition: str, account_id: str, resource_name: str,
                 **kwargs):
  if resource_name == 'metric-filter':
    arn = _get_with_parent('arn', kwargs)
    name = kwargs['filter_name']
    return f'{arn}:{resource_name}:{name}'
  elif resource_name == 'log-group':
    region = _get_with_parent('region', kwargs)
    id = kwargs['log_group_id']
    return f'arn:{partition}:logs:{region}:{account_id}:{resource_name.lower()}:{id}:*'
  raise GFInternal(f'Failed logs uri fn {resource_name} {kwargs}')


def _config_uri_fn(resource_name: str, **kwargs):
  if resource_name == 'ConfigurationRecorder':
    name = kwargs['name']
    region = _get_with_parent('region', kwargs)
    if region is None:
      raise GFInternal(f'Missing region in {kwargs}')
    return f'configurationRecorders/{region}/{name}'
  raise GFInternal(f'Failed logs uri fn {resource_name} {kwargs}')


def _apigatewayv2_uri_fn(partition: str, account_id: str, resource_name: str,
                         **kwargs):
  id = kwargs.get('id')
  if id is None:
    raise GFInternal(f'Missing id in {kwargs}')
  region = _get_with_parent('region', kwargs)
  if region is None:
    raise GFInternal(f'Missing region in {kwargs}')
  if resource_name == 'Api':
    return f'arn:{partition}:execute-api:{region}:{account_id}:{id}'
  elif resource_name == 'Stage':
    api_id = _get_with_parent('apiId', kwargs)
    if api_id is None:
      raise GFInternal(f'Missing ApiId in {kwargs}')
    return f'arn:{partition}:execute-api:{region}:{account_id}:{api_id}/{id}'
  raise GFInternal(f'Failed apigatewayv2 uri fn {resource_name} {kwargs}')


def _apigateway_uri_fn(partition: str, account_id: str, resource_name: str,
                       **kwargs):
  id = kwargs.get('id')
  if id is None:
    raise GFInternal(f'Missing id in {kwargs}')
  region = _get_with_parent('region', kwargs)
  if region is None:
    raise GFInternal(f'Missing region in {kwargs}')
  if resource_name == 'RestApi':
    return f'arn:{partition}:execute-api:{region}:{account_id}:{id}'
  elif resource_name == 'Stage':
    api_id = _get_with_parent('apiId', kwargs)
    if api_id is None:
      raise GFInternal(f'Missing ApiId in {kwargs}')
    return f'arn:{partition}:execute-api:{region}:{account_id}:{api_id}/{id}'
  raise GFInternal(f'Failed apigateway uri fn {resource_name} {kwargs}')


def _redshift_uri_fn(partition: str, account_id: str, resource_name: str,
                     **kwargs):
  id = kwargs.get('id')
  if id is None:
    raise GFInternal(f'Missing id in {kwargs}')
  region = _get_with_parent('region', kwargs)
  if region is None:
    raise GFInternal(f'Missing region in {kwargs}')
  if resource_name == 'cluster':
    return f'arn:{partition}:redshift:{region}:{account_id}:cluster:{id}'
  raise GFInternal(f'Failed redshift uri fn {resource_name} {kwargs}')


def arn_fn(service: str, partition: str, account_id: str, **kwargs) -> str:
  if 'uri' in kwargs:
    return kwargs['uri']
  resource_name = kwargs.pop('resource_name')
  if service == 'ec2':
    return _ec2_arn_fn(resource_name, account_id, partition, **kwargs)
  elif service == 's3':
    return _s3_bucket_arn_fn(kwargs['name'], partition)
  elif service == 'elb':
    return _elb_arn_fn(resource_name, partition, account_id, **kwargs)
  elif service == 'iam':
    return _iam_uri_fn(resource_name, **kwargs)
  elif service == 'logs':
    return _logs_uri_fn(partition, account_id, resource_name, **kwargs)
  elif service == 'config':
    return _config_uri_fn(resource_name, **kwargs)
  elif service == 'apigateway':
    return _apigateway_uri_fn(partition, account_id, resource_name, **kwargs)
  elif service == 'apigatewayv2':
    return _apigatewayv2_uri_fn(partition, account_id, resource_name, **kwargs)
  elif service == 'redshift':
    return _redshift_uri_fn(partition, account_id, resource_name, **kwargs)
  elif service == 'cloudwatch' and resource_name == 'metric':
    region = _get_with_parent('region', kwargs)
    if region is None:
      raise GFInternal(f'Missing region in {kwargs} for metric')
    name = kwargs['metric_name']
    namespace = kwargs['metric_namespace']
    return f'metrics/{region}/{namespace}/{name}'
  id = kwargs.get('id')
  if id is None:
    raise GFInternal(f'Missing id in {kwargs}')
  region = _get_with_parent('region', kwargs)
  if region is None:
    if service in ('route53', ):
      region = ''
    else:
      raise GFInternal(f'Missing region in {kwargs} for service {service}')
  if service in ('kms', 'route53'):
    return f'arn:{partition}:{service}:{region}:{account_id}:{resource_name.lower()}/{id}'
  return f'arn:{partition}:{service}:{region}:{account_id}:{resource_name.lower()}:{id}'


def get_arn_fn(master_account: str,
               partition='aws',
               subaccount: Optional[str] = None):
  if subaccount is None:
    account_id = master_account
  elif subaccount != master_account:
    raise GFError(
        f'Importing a non-master AWS account ({subaccount}) is not yet supported.'
    )
  else:
    account_id = subaccount
  return partial(arn_fn, partition=partition, account_id=account_id)