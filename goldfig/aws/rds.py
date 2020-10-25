import logging
from typing import Any, Generator, Tuple

from goldfig.aws.fetch import ServiceProxy
from goldfig.aws.svc import make_import_to_db, make_import_with_pool

_log = logging.getLogger(__name__)

HAS_TAGS = {
    'describe_db_instances': 'DBInstanceArn',
    'describe_db_clusters': 'DBClusterArn'
}


def _import_rds_region(proxy: ServiceProxy,
                       region: str) -> Generator[Tuple[str, Any], None, None]:
  for resource in proxy.resource_names():
    _log.info(f'Importing {resource} {region}')
    result = proxy.list(resource)
    if result is not None:
      resource_name, wrapper = result
      items = wrapper.get(resource_name, [])
      arn_for_tags = HAS_TAGS.get(resource)
      if arn_for_tags is not None:
        for item in items:
          arn = item[arn_for_tags]
          tags_result = proxy.list('list_tags_for_resource', ResourceName=arn)
          if tags_result is not None:
            item['Tags'] = tags_result[1].get('TagList', [])
      yield resource_name, items
    _log.info(f'Done with {resource}')


import_account_rds_region_with_pool = make_import_with_pool(
    'rds', _import_rds_region)

import_account_rds_region_to_db = make_import_to_db('rds', _import_rds_region)
