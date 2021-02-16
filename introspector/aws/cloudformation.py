import logging
from typing import Any, Iterator, Tuple

from introspector.aws.fetch import ServiceProxy
from introspector.aws.svc import RegionalService, ServiceSpec, resource_gate

_log = logging.getLogger(__name__)


def _import_cloudformation_stacks(proxy: ServiceProxy):
  stacks_resp = proxy.list('describe_stacks')
  if stacks_resp is not None:
    stacks = stacks_resp[1]['Stacks']
    for stack in stacks:
      yield 'Stack', stack


def _import_cloudformation_region(
    proxy: ServiceProxy, region: str,
    spec: ServiceSpec) -> Iterator[Tuple[str, Any]]:
  _log.info(f'import cloudformation in {region}')
  if resource_gate(spec, 'Stack'):
    yield from _import_cloudformation_stacks(proxy)


SVC = RegionalService('cloudformation', _import_cloudformation_region)