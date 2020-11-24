import concurrent.futures as f
import importlib
import os
from typing import List, Optional, Tuple, Union

from sqlalchemy.orm import Session

from goldfig import collect_exceptions, PathStack
from goldfig.aws.region import RegionCache
from goldfig.aws.svc import GlobalService, RegionalService
from goldfig.models import ImportJob, ProviderCredential

SVC_MODULES = [
    'acm', 'apigateway', 'apigatewayv2', 'autoscaling', 'cloudformation',
    'cloudfront', 'cloudtrail', 'cloudwatch', 'config', 'dynamodb', 'ec2',
    'ecr', 'ecs', 'elb', 'elbv2', 'iam', 'kms', 'lambdax', 'logs',
    'organizations', 'rds', 'redshift', 'route53', 's3', 'ses', 'sns', 'sqs',
    'ssm'
]


def run_single_session(db: Session,
                       import_job_id: int,
                       region_cache: RegionCache,
                       service: Optional[str] = None):

  for module_name in SVC_MODULES:
    module = importlib.import_module(f'{PKG_ROOT}.{module_name}')
    svc: Union[RegionalService, GlobalService] = module.SVC
    if service is None or service == svc.name:
      if isinstance(svc, RegionalService):
        fn = svc.db_fn()
        for region in region_cache.regions_for_service(svc.name):
          fn(db, import_job_id, region)
      else:
        fn = svc.db_fn()
        fn(db, import_job_id)
      db.flush()

  db.flush()


PKG_ROOT = '.'.join(__name__.split('.')[:-1])


def run_parallel_session(region_cache: RegionCache,
                         accounts: List[Tuple[str, ProviderCredential]],
                         import_job: ImportJob,
                         service: Optional[str] = None) -> List[str]:
  cpu_count = os.cpu_count()
  if cpu_count is not None:
    workers = max(1, cpu_count - 1)
  else:
    workers = 1
  ps = PathStack.from_import_job(import_job)
  with f.ProcessPoolExecutor(max_workers=workers) as pool:
    results = []

    for module_name in SVC_MODULES:
      module = importlib.import_module(f'{PKG_ROOT}.{module_name}')
      svc: Union[RegionalService, GlobalService] = module.SVC
      if service is None or service == svc.name:
        if isinstance(svc, RegionalService):
          fn = svc.pool_fn()
          for region in region_cache.regions_for_service(svc.name):
            results += fn(pool, import_job.id, region, ps, accounts)
        else:
          fn = svc.pool_fn()
          results += fn(pool, import_job.id, ps, accounts)

    f.wait(results, return_when='FIRST_EXCEPTION')
    # raise any exceptions
    return collect_exceptions(results)