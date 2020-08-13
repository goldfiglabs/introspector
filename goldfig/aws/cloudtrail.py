import concurrent.futures as f
import logging
from typing import Any, Dict, Generator, List, Tuple

from sqlalchemy.orm import Session

from goldfig import ImportWriter, db_import_writer, PathStack
from goldfig.aws import (account_paths_for_import, load_boto_session,
                         ProxyBuilder, make_proxy_builder,
                         load_boto_session_from_config)
from goldfig.aws.fetch import Proxy, ServiceProxy
from goldfig.bootstrap_db import import_session
from goldfig.models import ImportJob, ProviderCredential

_log = logging.getLogger(__name__)


def import_account_cloudtrail_region_to_db(db: Session, import_job_id: int,
                                           region: str,
                                           proxy_builder: ProxyBuilder):
  job: ImportJob = db.query(ImportJob).get(import_job_id)
  writer = db_import_writer(db, job.id, 'cloudtrail', phase=0, source='base')
  for path, account in account_paths_for_import(db, job):
    boto = load_boto_session(account)
    proxy = proxy_builder(boto)
    ps = PathStack.from_import_job(job).scope(path)
    _import_cloudtrail_region_to_db(proxy, writer, ps, region)


def _import_cloudtrail_region_to_db(proxy: Proxy, writer: ImportWriter,
                                    ps: PathStack, region: str):
  service_proxy = proxy.service('cloudtrail', region)
  ps = ps.scope(region)
  for resource_name, raw_resources in _import_cloudtrail_region(
      service_proxy, region):
    writer(ps, resource_name, raw_resources, {'region': region})


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


def _async_proxy(ps: PathStack, proxy_builder_args, import_job_id: int,
                 region: str, config: Dict):
  db = import_session()
  proxy_builder = make_proxy_builder(*proxy_builder_args)
  boto = load_boto_session_from_config(config)
  proxy = proxy_builder(boto)
  writer = db_import_writer(db,
                            import_job_id,
                            'cloudtrail',
                            phase=0,
                            source='base')
  _import_cloudtrail_region_to_db(proxy, writer, ps, region)
  db.commit()


def import_account_cloudtrail_region_with_pool(
    pool: f.ProcessPoolExecutor, proxy_builder_args, import_job_id: int,
    region: str, ps: PathStack,
    accounts: List[Tuple[str, ProviderCredential]]) -> List[f.Future]:
  results: List[f.Future] = []

  def queue_job(path: str, account: ProviderCredential) -> f.Future:
    return pool.submit(_async_proxy,
                       proxy_builder_args=proxy_builder_args,
                       import_job_id=import_job_id,
                       region=region,
                       ps=ps.scope(path),
                       config=account.config)

  for path, account in accounts:
    results.append(queue_job(path, account))
  return results