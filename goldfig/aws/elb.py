import concurrent.futures as f
from typing import Dict, List, Tuple

from sqlalchemy.orm import Session

from goldfig import ImportWriter, db_import_writer, PathStack
from goldfig.aws import (load_boto_session, account_paths_for_import,
                         ProxyBuilder, make_proxy_builder,
                         load_boto_session_from_config)
from goldfig.aws.fetch import Proxy, ServiceProxy
from goldfig.bootstrap_db import import_session
from goldfig.models import ImportJob, ProviderCredential


def import_elb(proxy: ServiceProxy, elb):
  result = elb.copy()
  elb_name = elb['LoadBalancerName']
  for resource in proxy.resource_names():
    canonical_name = proxy.canonical_name(resource)
    is_tags = canonical_name == 'DescribeTags'
    if is_tags:
      kwargs = {'LoadBalancerNames': [elb_name]}
    else:
      kwargs = {'LoadBalancerName': elb_name}
    list_result = proxy.list(resource, **kwargs)
    if list_result is not None:
      if is_tags:
        tag_descriptions = list_result[1]['TagDescriptions']
        if len(tag_descriptions) > 0:
          result['Tags'] = tag_descriptions[0]['Tags']
        else:
          result['Tags'] = []
      else:
        key = canonical_name[len('DescribeLoadBalancer'):]
        result[key] = list_result[1]
  return result


def _import_elb_region_to_db(proxy: Proxy, writer: ImportWriter, ps: PathStack,
                             region: str):
  ps = ps.scope(region)
  service_proxy = proxy.service('elb', region)
  for elb in _import_elb_region(service_proxy):
    writer(ps, 'LoadBalancer', elb, {'region': region})


def _is_v2(arn) -> bool:
  return ':loadbalancer/net/' in arn or ':loadbalancer/app/' in arn

def _import_elb_region(proxy: ServiceProxy):
  result = proxy.list('describe_load_balancers')
  if result is not None:
    elbs = result[1]
    for elb in elbs.get('LoadBalancerDescriptions', []):
      if not _is_v2(elb['LoadBalancerName']):
        yield import_elb(proxy, elb)


def _async_proxy(ps: PathStack, proxy_builder_args, import_job_id: int,
                 region: str, config: Dict, f):
  db = import_session()
  proxy_builder = make_proxy_builder(*proxy_builder_args)
  boto = load_boto_session_from_config(config)
  proxy = proxy_builder(boto)
  writer = db_import_writer(db, import_job_id, 'elb', phase=0, source='base')
  f(proxy, writer, ps, region)
  db.commit()


def import_account_elb_region_with_pool(
    pool: f.ProcessPoolExecutor, proxy_builder_args, import_job_id: int,
    region: str, ps: PathStack, accounts: List[Tuple[str,
                                                     ProviderCredential]]):
  results: List[f.Future] = []

  def queue_job(fn, path: str, account: ProviderCredential):
    return pool.submit(_async_proxy,
                       proxy_builder_args=proxy_builder_args,
                       import_job_id=import_job_id,
                       region=region,
                       ps=ps.scope(path),
                       config=account.config,
                       f=fn)

  for path, account in accounts:
    results.append(queue_job(_import_elb_region_to_db, path, account))
  return results


def import_account_elb_region_to_db(db: Session, import_job_id: int,
                                    region: str, proxy_builder: ProxyBuilder):
  job: ImportJob = db.query(ImportJob).get(import_job_id)
  writer = db_import_writer(db, job.id, 'elb', phase=0, source='base')
  for path, account in account_paths_for_import(db, job):
    boto = load_boto_session(account)
    proxy = proxy_builder(boto)
    ps = PathStack.from_import_job(job).scope(path)
    _import_elb_region_to_db(proxy, writer, ps, region)
