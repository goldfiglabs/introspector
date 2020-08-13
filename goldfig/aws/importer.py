import concurrent.futures as f
import os
from typing import List, Tuple

from sqlalchemy.orm import Session

from goldfig import collect_exceptions, PathStack
from goldfig.aws import ProxyBuilder
from goldfig.aws.iam import import_account_iam_to_db, import_account_iam_with_pool
from goldfig.aws.ec2 import import_account_ec2_region_to_db, import_account_ec2_region_with_pool
from goldfig.aws.elb import import_account_elb_region_to_db, import_account_elb_region_with_pool
from goldfig.aws.s3 import import_account_s3_to_db, import_account_s3_with_pool
from goldfig.aws.lambdax import import_account_lambda_region_to_db, import_account_lambda_region_with_pool
from goldfig.aws.cloudtrail import import_account_cloudtrail_region_to_db, import_account_cloudtrail_region_with_pool
from goldfig.aws.cloudwatch import import_account_cloudwatch_region_to_db, import_account_cloudwatch_region_with_pool
from goldfig.aws.region import RegionCache
from goldfig.aws.rds import import_account_rds_region_to_db, import_account_rds_region_with_pool
from goldfig.models import ImportJob, ProviderCredential


def run_single_session(db: Session, import_job_id: int,
                       proxy_builder: ProxyBuilder, region_cache: RegionCache):

  import_account_iam_to_db(db, import_job_id, proxy_builder)
  db.flush()
  for region in region_cache.regions_for_service('ec2'):
    import_account_ec2_region_to_db(db, import_job_id, region, proxy_builder)
    db.flush()
  for region in region_cache.regions_for_service('elb'):
    import_account_elb_region_to_db(db, import_job_id, region, proxy_builder)
    db.flush()
  for region in region_cache.regions_for_service('lambda'):
    import_account_lambda_region_to_db(db, import_job_id, region,
                                       proxy_builder)
    db.flush()
  for region in region_cache.regions_for_service('rds'):
    import_account_rds_region_to_db(db, import_job_id, region, proxy_builder)
    db.flush()

  for region in region_cache.regions_for_service('cloudtrail'):
    import_account_cloudtrail_region_to_db(db, import_job_id, region,
                                           proxy_builder)
    db.flush()

  for region in region_cache.regions_for_service('cloudwatch'):
    import_account_cloudwatch_region_to_db(db, import_job_id, region,
                                           proxy_builder)
    db.flush()

  import_account_s3_to_db(db, import_job_id, proxy_builder)


def run_parallel_session(region_cache: RegionCache,
                         accounts: List[Tuple[str, ProviderCredential]],
                         import_job: ImportJob,
                         proxy_builder_args) -> List[str]:
  cpu_count = os.cpu_count()
  if cpu_count is not None:
    workers = max(1, cpu_count - 1)
  else:
    workers = 1
  ps = PathStack.from_import_job(import_job)
  with f.ProcessPoolExecutor(max_workers=workers) as pool:
    results = import_account_iam_with_pool(pool, proxy_builder_args,
                                           import_job.id, ps, accounts)
    for region in region_cache.regions_for_service('ec2'):
      results += import_account_ec2_region_with_pool(pool, proxy_builder_args,
                                                     import_job.id, region, ps,
                                                     accounts)
    for region in region_cache.regions_for_service('elb'):
      results += import_account_elb_region_with_pool(pool, proxy_builder_args,
                                                     import_job.id, region, ps,
                                                     accounts)
    results += import_account_s3_with_pool(pool, proxy_builder_args,
                                           import_job.id, ps, accounts)
    for region in region_cache.regions_for_service('rds'):
      results += import_account_rds_region_with_pool(pool, proxy_builder_args,
                                                     import_job.id, region, ps,
                                                     accounts)
    for region in region_cache.regions_for_service('lambda'):
      results += import_account_lambda_region_with_pool(
          pool, proxy_builder_args, import_job.id, region, ps, accounts)

    for region in region_cache.regions_for_service('cloudtrail'):
      results += import_account_cloudtrail_region_with_pool(
          pool, proxy_builder_args, import_job.id, region, ps, accounts)

    for region in region_cache.regions_for_service('cloudwatch'):
      results += import_account_cloudwatch_region_with_pool(
          pool, proxy_builder_args, import_job.id, region, ps, accounts)

    f.wait(results)
    # raise any exceptions
    return collect_exceptions(results)