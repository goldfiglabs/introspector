import json
import logging
from typing import Any, Dict, Generator, Optional, Tuple

from botocore.exceptions import ClientError

from introspector.aws.fetch import ServiceProxy
from introspector.aws.svc import RegionalService, ServiceSpec, resource_gate

_log = logging.getLogger(__name__)

HAS_TAGS = {'list_functions': 'FunctionArn'}


def _get_policy(proxy: ServiceProxy, arn: str) -> Optional[Dict]:
  try:
    policy_resp = proxy.get('get_policy', FunctionName=arn)
    if policy_resp is not None:
      return json.loads(policy_resp['Policy'])
  except ClientError as e:
    if e.response.get('Error', {}).get('Code') != 'ResourceNotFoundException':
      raise
  return None


def _import_function(proxy: ServiceProxy, function: Dict, spec: ServiceSpec):
  name = function['FunctionName']
  arn = function['FunctionArn']
  if resource_gate(spec, 'FunctionVersion'):
    versions_resp = proxy.list('list_versions_by_function', FunctionName=name)
    if versions_resp is not None:
      versions = versions_resp[1]['Versions']
      for version in versions:
        version['ParentFunctionArn'] = arn
        version['Policy'] = _get_policy(proxy, version['FunctionArn'])
        yield 'FunctionVersion', version
  if resource_gate(spec, 'Alias'):
    aliases_resp = proxy.list('list_aliases', FunctionName=name)
    if aliases_resp is not None:
      aliases = aliases_resp[1]['Aliases']
      for alias in aliases:
        alias['FunctionArn'] = arn
        alias['Policy'] = _get_policy(proxy, alias['AliasArn'])
        yield 'Alias', alias


def _import_functions(proxy: ServiceProxy, spec: ServiceSpec):
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
      function['Policy'] = _get_policy(proxy, function['FunctionArn'])
      yield 'Function', function
      yield from _import_function(proxy, function, spec)

def _import_lambda_region(
    proxy: ServiceProxy, region: str,
    spec: ServiceSpec) -> Generator[Tuple[str, Any], None, None]:
  if resource_gate(spec, 'Function'):
    _log.info(f'Importing functions in {region}')
    yield from _import_functions(proxy, spec)
  # TODO: layers, event sources


SVC = RegionalService('lambda', _import_lambda_region)