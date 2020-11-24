import logging
from typing import Any, Iterator, Tuple

from goldfig.aws.fetch import ServiceProxy
from goldfig.aws.svc import RegionalService

_log = logging.getLogger(__name__)


def _import_cloudformation_stacks(proxy: ServiceProxy):
  stacks_resp = proxy.list('describe_stacks')
  if stacks_resp is not None:
    stacks = stacks_resp[1]['Stacks']
    for stack in stacks:
      yield 'Stack', stack


def _import_cloudformation_region(proxy: ServiceProxy,
                                  region: str) -> Iterator[Tuple[str, Any]]:
  _log.info(f'import cloudformation in {region}')
  yield from _import_cloudformation_stacks(proxy)


SVC = RegionalService('cloudformation', _import_cloudformation_region)