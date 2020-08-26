import logging
from typing import Any, Dict, Generator, Tuple

from goldfig.aws.fetch import ServiceProxy
from goldfig.aws.svc import make_import_to_db, make_import_with_pool

_log = logging.getLogger(__name__)


def _import_trail(proxy: ServiceProxy, trail_data: Dict):
  name = trail_data['Name']
  arn = trail_data['TrailARN']
  status = proxy.get('get_trail_status', Name=name)
  trail_data.update(status)
  tags_result = proxy.list('list_tags', ResourceIdList=[arn])
  if tags_result is not None:
    tag_list = tags_result[1]['ResourceTagList']
    if len(tag_list) > 0:
      trail_data['Tags'] = tag_list[0]['TagsList']
  event_selectors = proxy.get('get_event_selectors', TrailName=name)
  trail_data['EventSelectors'] = event_selectors['EventSelectors']
  return trail_data


def _import_trails(proxy: ServiceProxy, region: str):
  trails_resp = proxy.list('describe_trails')
  if trails_resp is not None:
    trails = trails_resp[1]['trailList']
    if trails is not None:
      for trail in trails:
        if trail is not None:
          # When you create a trail in the console you create a single trail. It can be multiregional
          # which means it runs in all regions. The console still shows this as one however the api will
          # return an object with the same ARN in every region. This is to squash that down to one.
          if (trail['IsMultiRegionTrail'] is False) or (
              trail['IsMultiRegionTrail'] and trail['HomeRegion'] == region):
            yield 'Trail', _import_trail(proxy, trail)


def _import_cloudtrail_region(
    proxy: ServiceProxy,
    region: str) -> Generator[Tuple[str, Any], None, None]:
  _log.info(f'importing describe_trails')
  yield from _import_trails(proxy, region)


import_account_cloudtrail_region_to_db = make_import_to_db(
    'cloudtrail', _import_cloudtrail_region)

import_account_cloudtrail_region_with_pool = make_import_with_pool(
    'cloudtrail', _import_cloudtrail_region)
