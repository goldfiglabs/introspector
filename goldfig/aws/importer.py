import concurrent.futures as f
import os
from typing import List, Tuple

from sqlalchemy.orm import Session

from goldfig import collect_exceptions, PathStack
from goldfig.aws.acm import import_account_acm_region_to_db, import_account_acm_region_with_pool
from goldfig.aws.apigateway import import_account_apigateway_region_to_db, import_account_apigateway_region_with_pool
from goldfig.aws.apigatewayv2 import import_account_apigatewayv2_region_to_db, import_account_apigatewayv2_region_with_pool
from goldfig.aws.iam import import_account_iam_to_db, import_account_iam_with_pool
from goldfig.aws.dynamodb import import_account_dynamodb_region_to_db, import_account_dynamodb_region_with_pool
from goldfig.aws.ec2 import import_account_ec2_region_to_db, import_account_ec2_region_with_pool
from goldfig.aws.ecs import import_account_ecs_region_to_db, import_account_ecs_region_with_pool
from goldfig.aws.elb import import_account_elb_region_to_db, import_account_elb_region_with_pool
from goldfig.aws.elbv2 import import_account_elbv2_region_to_db, import_account_elbv2_region_with_pool
from goldfig.aws.s3 import import_account_s3_to_db, import_account_s3_with_pool
from goldfig.aws.kms import import_account_kms_region_to_db, import_account_kms_region_with_pool
from goldfig.aws.lambdax import import_account_lambda_region_to_db, import_account_lambda_region_with_pool
from goldfig.aws.logs import import_account_logs_region_to_db, import_account_logs_region_with_pool
from goldfig.aws.cloudfront import import_account_cloudfront_to_db, import_account_cloudfront_with_pool
from goldfig.aws.cloudtrail import import_account_cloudtrail_region_to_db, import_account_cloudtrail_region_with_pool
from goldfig.aws.cloudwatch import import_account_cloudwatch_region_to_db, import_account_cloudwatch_region_with_pool
from goldfig.aws.config import import_account_config_region_to_db, import_account_config_region_with_pool
from goldfig.aws.region import RegionCache
from goldfig.aws.rds import import_account_rds_region_to_db, import_account_rds_region_with_pool
from goldfig.aws.redshift import import_account_redshift_region_to_db, import_account_redshift_region_with_pool
from goldfig.aws.route53 import import_account_route53_to_db, import_account_route53_with_pool
from goldfig.aws.ses import import_account_ses_region_to_db, import_account_ses_region_with_pool
from goldfig.aws.sns import import_account_sns_region_to_db, import_account_sns_region_with_pool
from goldfig.aws.sqs import import_account_sqs_region_to_db, import_account_sqs_region_with_pool
from goldfig.aws.ssm import import_account_ssm_region_to_db, import_account_ssm_region_with_pool
from goldfig.models import ImportJob, ProviderCredential


def run_single_session(db: Session, import_job_id: int,
                       region_cache: RegionCache):

  import_account_iam_to_db(db, import_job_id)
  db.flush()

  import_account_route53_to_db(db, import_job_id)
  db.flush()

  for region in region_cache.regions_for_service('dynamodb'):
    import_account_dynamodb_region_to_db(db, import_job_id, region)
    db.flush()

  for region in region_cache.regions_for_service('ec2'):
    import_account_ec2_region_to_db(db, import_job_id, region)
    db.flush()

  for region in region_cache.regions_for_service('ecs'):
    import_account_ecs_region_to_db(db, import_job_id, region)
    db.flush()

  for region in region_cache.regions_for_service('kms'):
    import_account_kms_region_to_db(db, import_job_id, region)
    db.flush()

  for region in region_cache.regions_for_service('elb'):
    import_account_elb_region_to_db(db, import_job_id, region)
    db.flush()

  for region in region_cache.regions_for_service('elbv2'):
    import_account_elbv2_region_to_db(db, import_job_id, region)
    db.flush()

  for region in region_cache.regions_for_service('lambda'):
    import_account_lambda_region_to_db(db, import_job_id, region)
    db.flush()
  for region in region_cache.regions_for_service('rds'):
    import_account_rds_region_to_db(db, import_job_id, region)
    db.flush()

  for region in region_cache.regions_for_service('cloudtrail'):
    import_account_cloudtrail_region_to_db(db, import_job_id, region)
    db.flush()

  for region in region_cache.regions_for_service('cloudwatch'):
    import_account_cloudwatch_region_to_db(db, import_job_id, region)
    db.flush()

  for region in region_cache.regions_for_service('config'):
    import_account_config_region_to_db(db, import_job_id, region)
    db.flush()

  for region in region_cache.regions_for_service('logs'):
    import_account_logs_region_to_db(db, import_job_id, region)
    db.flush()

  for region in region_cache.regions_for_service('ses'):
    import_account_ses_region_to_db(db, import_job_id, region)
    db.flush()

  for region in region_cache.regions_for_service('sns'):
    import_account_sns_region_to_db(db, import_job_id, region)
    db.flush()

  for region in region_cache.regions_for_service('sqs'):
    import_account_sqs_region_to_db(db, import_job_id, region)
    db.flush()

  for region in region_cache.regions_for_service('ssm'):
    import_account_ssm_region_to_db(db, import_job_id, region)
    db.flush()

  import_account_cloudfront_to_db(db, import_job_id)
  db.flush()

  for region in region_cache.regions_for_service('apigatewayv2'):
    import_account_apigatewayv2_region_to_db(db, import_job_id, region)
    db.flush()

  for region in region_cache.regions_for_service('apigateway'):
    import_account_apigateway_region_to_db(db, import_job_id, region)
    db.flush()

  for region in region_cache.regions_for_service('acm'):
    import_account_acm_region_to_db(db, import_job_id, region)
    db.flush()

  for region in region_cache.regions_for_service('redshift'):
    import_account_redshift_region_to_db(db, import_job_id, region)
    db.flush()

  import_account_s3_to_db(db, import_job_id)


def run_parallel_session(region_cache: RegionCache,
                         accounts: List[Tuple[str, ProviderCredential]],
                         import_job: ImportJob) -> List[str]:
  cpu_count = os.cpu_count()
  if cpu_count is not None:
    workers = max(1, cpu_count - 1)
  else:
    workers = 1
  ps = PathStack.from_import_job(import_job)
  with f.ProcessPoolExecutor(max_workers=workers) as pool:
    results = import_account_iam_with_pool(pool, import_job.id, ps, accounts)

    results += import_account_route53_with_pool(pool, import_job.id, ps,
                                                accounts)

    for region in region_cache.regions_for_service('dynamodb'):
      results += import_account_dynamodb_region_with_pool(
          pool, import_job.id, region, ps, accounts)

    for region in region_cache.regions_for_service('ec2'):
      results += import_account_ec2_region_with_pool(pool, import_job.id,
                                                     region, ps, accounts)

    for region in region_cache.regions_for_service('ecs'):
      results += import_account_ecs_region_with_pool(pool, import_job.id,
                                                     region, ps, accounts)

    for region in region_cache.regions_for_service('kms'):
      results += import_account_kms_region_with_pool(pool, import_job.id,
                                                     region, ps, accounts)

    for region in region_cache.regions_for_service('elb'):
      results += import_account_elb_region_with_pool(pool, import_job.id,
                                                     region, ps, accounts)

    for region in region_cache.regions_for_service('elbv2'):
      results += import_account_elbv2_region_with_pool(pool, import_job.id,
                                                       region, ps, accounts)

    results += import_account_s3_with_pool(pool, import_job.id, ps, accounts)
    for region in region_cache.regions_for_service('rds'):
      results += import_account_rds_region_with_pool(pool, import_job.id,
                                                     region, ps, accounts)
    for region in region_cache.regions_for_service('lambda'):
      results += import_account_lambda_region_with_pool(
          pool, import_job.id, region, ps, accounts)

    for region in region_cache.regions_for_service('cloudtrail'):
      results += import_account_cloudtrail_region_with_pool(
          pool, import_job.id, region, ps, accounts)

    for region in region_cache.regions_for_service('cloudwatch'):
      results += import_account_cloudwatch_region_with_pool(
          pool, import_job.id, region, ps, accounts)

    for region in region_cache.regions_for_service('config'):
      results += import_account_config_region_with_pool(
          pool, import_job.id, region, ps, accounts)

    for region in region_cache.regions_for_service('logs'):
      results += import_account_logs_region_with_pool(pool, import_job.id,
                                                      region, ps, accounts)

    for region in region_cache.regions_for_service('ses'):
      results += import_account_ses_region_with_pool(pool, import_job.id,
                                                     region, ps, accounts)

    for region in region_cache.regions_for_service('sns'):
      results += import_account_sns_region_with_pool(pool, import_job.id,
                                                     region, ps, accounts)

    for region in region_cache.regions_for_service('sqs'):
      results += import_account_sqs_region_with_pool(pool, import_job.id,
                                                     region, ps, accounts)

    for region in region_cache.regions_for_service('ssm'):
      results += import_account_ssm_region_with_pool(pool, import_job.id,
                                                     region, ps, accounts)

    results += import_account_cloudfront_with_pool(pool, import_job.id, ps,
                                                   accounts)

    for region in region_cache.regions_for_service('apigatewayv2'):
      results += import_account_apigatewayv2_region_with_pool(
          pool, import_job.id, region, ps, accounts)

    for region in region_cache.regions_for_service('apigateway'):
      results += import_account_apigateway_region_with_pool(
          pool, import_job.id, region, ps, accounts)

    for region in region_cache.regions_for_service('acm'):
      results += import_account_acm_region_with_pool(pool, import_job.id,
                                                     region, ps, accounts)

    for region in region_cache.regions_for_service('redshift'):
      results += import_account_redshift_region_with_pool(
          pool, import_job.id, region, ps, accounts)
    f.wait(results)
    # raise any exceptions
    return collect_exceptions(results)