import concurrent.futures as f
import importlib
import logging
import os
from typing import Iterable, List, Optional, Tuple, Union

from sqlalchemy.orm import Session

from goldfig import collect_exceptions, PathStack
from goldfig.aws.region import RegionCache
from goldfig.aws.svc import GlobalService, RegionalService
from goldfig.models import ImportJob, ProviderCredential

SVC_MODULES = [
    'acm', 'apigateway', 'apigatewayv2', 'autoscaling', 'cloudformation',
    'cloudfront', 'cloudtrail', 'cloudwatch', 'config', 'dynamodb', 'ec2',
    'ecr', 'ecs', 'eks', 'elasticbeanstalk', 'elb', 'elbv2', 'es', 'iam',
    'kms', 'lambdax', 'logs', 'organizations', 'rds', 'redshift', 'route53',
    's3', 'ses', 'sns', 'sqs', 'ssm'
]

GOV_SKIPLIST = ['cloudfront']

_log = logging.getLogger(__name__)


def _modules(is_gov_cloud: bool) -> Iterable[str]:
  if is_gov_cloud:
    for svc in SVC_MODULES:
      if svc not in GOV_SKIPLIST:
        yield svc
  else:
    yield from SVC_MODULES


def run_single_session(db: Session,
                       import_job_id: int,
                       region_cache: RegionCache,
                       is_gov_cloud: bool,
                       service: Optional[str] = None):

  for module_name in _modules(is_gov_cloud):
    module = importlib.import_module(f'{PKG_ROOT}.{module_name}')
    svc: Union[RegionalService, GlobalService] = module.__dict__['SVC']
    if service is None or service == svc.name:
      if isinstance(svc, RegionalService):
        regional_fn = svc.db_fn()
        for region in region_cache.regions_for_service(svc.name):
          regional_fn(db, import_job_id, region)
      else:
        global_fn = svc.db_fn()
        global_fn(db, import_job_id)
      db.flush()

  db.flush()


PKG_ROOT = '.'.join(__name__.split('.')[:-1])


def run_parallel_session(region_cache: RegionCache,
                         accounts: List[Tuple[str, ProviderCredential]],
                         import_job: ImportJob,
                         is_gov_cloud: bool,
                         service: Optional[str] = None) -> List[str]:
  cpu_count = os.cpu_count()
  if cpu_count is not None:
    workers = max(1, cpu_count - 1)
  else:
    workers = 1
  ps = PathStack.from_import_job(import_job)
  with f.ProcessPoolExecutor(max_workers=workers * 4) as pool:
    results = []

    for module_name in _modules(is_gov_cloud):
      module = importlib.import_module(f'{PKG_ROOT}.{module_name}')
      svc: Union[RegionalService, GlobalService] = module.__dict__['SVC']
      if service is None or service == svc.name:
        _log.info(f'importing {svc.name}')
        if isinstance(svc, RegionalService):
          regional_fn = svc.pool_fn()
          for region in region_cache.regions_for_service(svc.name):
            _log.info(f'region {region}')
            results += regional_fn(pool, import_job.id,
                                   import_job.provider_account_id, region, ps,
                                   accounts)
        else:
          global_fn = svc.pool_fn()
          results += global_fn(pool, import_job.id,
                               import_job.provider_account_id, ps, accounts)
      else:
        _log.debug(f'skipped {svc.name}')

    f.wait(results, return_when='FIRST_EXCEPTION')
    # raise any exceptions
    return collect_exceptions(results)