import concurrent.futures as f
import logging
import os
from typing import Any, Callable, Dict, Generator, Iterator, List, Optional, Tuple

from botocore.loaders import create_loader
from botocore.regions import EndpointResolver
from botocore.exceptions import ClientError
import botocore.session as boto
from sqlalchemy.orm import Session

from goldfig import collect_exceptions, PathStack
from goldfig.aws.fetch import Proxy
from goldfig.error import GFInternal
from goldfig.models import ImportJob, ProviderAccount, ProviderCredential

ProxyBuilder = Callable[[boto.Session], Proxy]
_log = logging.getLogger(__name__)


def make_proxy_builder(use_cache: bool = False,
                       patch_id: Optional[int] = None) -> ProxyBuilder:
  def _fn(boto: boto.Session) -> Proxy:
    if use_cache:
      return Proxy.build(boto, patch_id=patch_id)
    else:
      return Proxy.dummy(boto)

  return _fn


def _patch_boto(session: boto.Session):
  parser_factory = session.get_component('response_parser_factory')
  parser_factory.set_parser_defaults(timestamp_parser=lambda x: x)


def get_boto_session() -> boto.Session:
  session = boto.get_session()
  _patch_boto(session)
  return session


def create_provider_and_credential(db: Session, proxy: Proxy,
                                   identity) -> ProviderAccount:
  org = proxy.service('organizations')
  org_resp = org.get('describe_organization')['Organization']
  org_id = org_resp['Id']
  provider = ProviderAccount(provider='aws', name=org_id)
  db.add(provider)
  db.flush()
  credential = ProviderCredential(scope=identity['Account'],
                                  principal_uri=identity['Arn'],
                                  config={'from_environment': True})
  credential.provider_id = provider.id
  db.add(credential)
  return provider


def walk_graph(org, graph) -> Generator[Tuple[str, str, Dict], None, None]:
  yield '', 'Organization', org
  ou_paths = graph['organizational_units']
  accounts = graph['accounts']
  for path, entries in ou_paths.items():
    for entry in entries:
      if path == '':
        entry_path = entry['Id']
        typ = 'Root'
      else:
        entry_path = f'{path}/{entry["Id"]}'
        typ = 'OrganizationalUnit'
      yield entry_path, typ, entry
      accounts_at_path = accounts.get(entry_path, [])
      for account in accounts_at_path:
        # No accounts at empty path, only the root is there
        yield f'{entry_path}/{account["Id"]}', 'Account', account


def build_aws_import_job(db: Session, proxy_builder: ProxyBuilder,
                         provider: ProviderAccount) -> Dict:
  accounts = ProviderCredential.for_provider(db, provider.id)
  if len(accounts) != 1:
    raise NotImplementedError(
        'Currently only one AWS account per org is supported')
  account = accounts[0]
  session = load_boto_session(account)
  proxy = proxy_builder(session)
  org, graph = _build_org_graph(proxy)
  sts = session.create_client('sts')
  identity = sts.get_caller_identity()
  return {
      'account': {
          'account_id': org['Id'],
          'provider': 'aws'
      },
      'principal': {
          'provider_id': identity['UserId'],
          'provider_uri': identity['Arn']
      },
      'aws_org': org,
      'aws_graph': graph
  }


def _require_resp(tup: Optional[Tuple[str, Dict[str, Any]]]) -> Dict[str, Any]:
  if tup is None:
    raise GFInternal(f'Missing response')
  else:
    return tup[1]


def _build_org_graph(proxy: Proxy):
  org = proxy.service('organizations')
  org_resp = org.get('describe_organization')['Organization']
  roots_resp = _require_resp(org.list('list_roots'))
  roots = roots_resp['Roots']
  accounts = {}
  organizational_units = {}

  def build_graph(parent_id: str, path: List[str]):
    accounts_resp = _require_resp(
        org.list('list_accounts_for_parent', ParentId=parent_id))
    next_path = [*path, parent_id]
    path_str = '/'.join(next_path)
    accounts[path_str] = accounts_resp['Accounts']
    organizational_units_resp = _require_resp(
        org.list('list_organizational_units_for_parent', ParentId=parent_id))
    ous = organizational_units_resp['OrganizationalUnits']
    if len(ous) > 0:
      organizational_units[path_str] = ous
      for ou in ous:
        build_graph(parent_id=ou['Id'], path=next_path)

  organizational_units[''] = roots
  for root in roots:
    build_graph(root['Id'], [])
  return org_resp, {
      'accounts': accounts,
      'organizational_units': organizational_units
  }


def load_boto_session_from_config(config: Dict[str, Any]) -> boto.Session:
  if config.get('from_environment', False):
    session = boto.get_session()
  else:
    access_key = config['access_key']
    secret_key = config['secret_key']
    session = boto.Session()
    session.set_credentials(access_key, secret_key)
  _patch_boto(session)
  return session


def load_boto_session(provider_credential: ProviderCredential) -> boto.Session:
  config = provider_credential.config
  return load_boto_session_from_config(config)


def region_is_available(region):
  # https://www.cloudar.be/awsblog/checking-if-a-region-is-enabled-using-the-aws-api/
  # https://stackoverflow.com/a/56184952
  regional_sts = get_boto_session().create_client('sts', region_name=region)
  try:
    regional_sts.get_caller_identity()
    return True
  except ClientError:
    return False


def get_region_fn() -> Callable[[str], Iterator[str]]:
  data_dir = os.path.join(os.path.dirname(boto.__file__), 'data')
  loader = create_loader(data_dir)
  endpoint_data = loader.load_data('endpoints')
  endpoints = EndpointResolver(endpoint_data)

  def get_regions_for_service(service: str) -> Iterator[str]:
    sm = loader.load_service_model(service, type_name='service-2')
    prefix = sm['metadata'].get('endpointPrefix', service)
    return filter(
        lambda region: region_is_available(region),
        endpoints.get_available_endpoints(prefix, partition_name='aws'))

  return get_regions_for_service


def run_parallel_session(accounts: List[Tuple[str, ProviderCredential]],
                         import_job: ImportJob,
                         proxy_builder_args) -> List[str]:
  from goldfig.aws.iam import import_account_iam_with_pool
  from goldfig.aws.ec2 import import_account_ec2_region_with_pool
  from goldfig.aws.elb import import_account_elb_region_with_pool
  from goldfig.aws.rds import import_account_rds_region_with_pool
  from goldfig.aws.s3 import import_account_s3_with_pool
  from goldfig.aws.lambdax import import_account_lambda_region_with_pool

  cpu_count = os.cpu_count()
  if cpu_count is not None:
    workers = max(1, cpu_count - 1)
  else:
    workers = 1
  ps = PathStack.from_import_job(import_job)
  get_region_for_service = get_region_fn()
  with f.ProcessPoolExecutor(max_workers=workers) as pool:
    results = import_account_iam_with_pool(pool, proxy_builder_args,
                                           import_job.id, ps, accounts)
    for region in get_region_for_service('ec2'):
      results += import_account_ec2_region_with_pool(pool, proxy_builder_args,
                                                     import_job.id, region, ps,
                                                     accounts)
    for region in get_region_for_service('elb'):
      results += import_account_elb_region_with_pool(pool, proxy_builder_args,
                                                     import_job.id, region, ps,
                                                     accounts)
    results += import_account_s3_with_pool(pool, proxy_builder_args,
                                           import_job.id, ps, accounts)
    for region in get_region_for_service('rds'):
      results += import_account_rds_region_with_pool(pool, proxy_builder_args,
                                                     import_job.id, region, ps,
                                                     accounts)
    for region in get_region_for_service('lambda'):
      results += import_account_lambda_region_with_pool(
          pool, proxy_builder_args, import_job.id, region, ps, accounts)
    f.wait(results)
    # raise any exceptions
    return collect_exceptions(results)


def run_single_session(db: Session, import_job_id: int,
                       proxy_builder: ProxyBuilder):
  from goldfig.aws.iam import import_account_iam_to_db
  from goldfig.aws.ec2 import import_account_ec2_region_to_db
  from goldfig.aws.elb import import_account_elb_region_to_db
  from goldfig.aws.s3 import import_account_s3_to_db
  from goldfig.aws.lambdax import import_account_lambda_region_to_db
  from goldfig.aws.rds import import_account_rds_region_to_db

  import_account_iam_to_db(db, import_job_id, proxy_builder)
  db.flush()
  get_region_for_service = get_region_fn()
  for region in get_region_for_service('ec2'):
    import_account_ec2_region_to_db(db, import_job_id, region, proxy_builder)
    db.flush()
  for region in get_region_for_service('elb'):
    import_account_elb_region_to_db(db, import_job_id, region, proxy_builder)
    db.flush()
  for region in get_region_for_service('lambda'):
    import_account_lambda_region_to_db(db, import_job_id, region,
                                       proxy_builder)
    db.flush()
  for region in get_region_for_service('rds'):
    import_account_rds_region_to_db(db, import_job_id, region, proxy_builder)
    db.flush()

  import_account_s3_to_db(db, import_job_id, proxy_builder)


def map_import(db: Session, import_job_id: int, proxy_builder: ProxyBuilder):
  from goldfig.aws.map import map_import as library_map_import
  import_job: ImportJob = db.query(ImportJob).get(import_job_id)

  library_map_import(db, import_job, proxy_builder)


def account_paths_for_import(
    db: Session,
    import_job: ImportJob) -> List[Tuple[str, ProviderCredential]]:
  creds = db.query(ProviderCredential).filter(
      ProviderCredential.provider_id == import_job.provider_account_id).all()

  def find_credential(account_id: str) -> ProviderCredential:
    return next(cred for cred in creds if cred.scope == account_id)

  account_paths = import_job.aws_config.graph.accounts
  results = []
  for path, accounts in account_paths.items():
    for account in accounts:
      try:
        cred = find_credential(account.id)
        results.append((f'{path}/{cred.scope}', cred))
      except StopIteration:
        # If we don't have credentials, don't import it
        _log.info(f'Skipping account id {account.id}, no credentials')
        continue
  return results
