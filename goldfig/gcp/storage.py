import concurrent.futures as f
from typing import Dict, List

import googleapiclient.errors

from sqlalchemy.orm import Session

from goldfig import ImportWriter, db_import_writer, PathStack
from goldfig.bootstrap_db import import_session
from goldfig.gcp import credentials_from_config, projects, ProxyBuilder, make_proxy_builder
from goldfig.gcp.fetch import Proxy, ServiceProxy
from goldfig.models import ImportJob

SKIPLIST = [
    'objects',
    'objectAccessControls',
    'projects',
    'buckets',
    'channels',  # all you can do is stop it...
    'bucketAccessControls',  # Included in bucket response
    'defaultObjectAccessControls,'  # Included in bucket response
]

IAM_POLICY_VERSION = 3


def _import_bucket(proxy: ServiceProxy, bucket):
  iam_policy = proxy.call_method('buckets',
                                 'getIamPolicy',
                                 bucket=bucket['name'])
  bucket['iam_policy'] = iam_policy
  for resource_name in proxy.resource_names():
    if resource_name in SKIPLIST:
      continue
    try:
      all_items = proxy.list(resource_name, bucket=bucket['name'])
      if len(all_items) > 0:
        bucket[resource_name] = all_items
    except googleapiclient.errors.HttpError as e:
      if resource_name in (
          'bucketAccessControls',
          'defaultObjectAccessControls') and e.resp.status == 400:
        pass
      else:
        raise


def _import_gcp_storage(proxy: Proxy, project: str):
  service = proxy.service('storage', 'v1')
  for bucket in service.list('buckets', projection='full', project=project):
    _import_bucket(service, bucket)
    yield bucket


def import_account_storage_to_db(db: Session, import_job_id: int,
                                 proxy_builder: ProxyBuilder):
  job = db.query(ImportJob).get(import_job_id)
  writer = db_import_writer(db, job.id, 'storage', phase=0, source='base')
  creds = credentials_from_config(job.configuration)
  proxy = proxy_builder(creds)
  graph = job.configuration['gcp_graph']
  ps = PathStack.from_import_job(job)
  for path, project in projects(graph):
    project_id = project['projectId']
    if path == '':
      scope = 'projects/' + project_id
    else:
      scope = path + '/projects/' + project_id
    _import_gcp_storage_to_db(proxy, writer, ps.scope(scope), project_id)


def _async_proxy(import_job_id: int, config: Dict, proxy_builder_args,
                 ps: PathStack, project: str):
  db = import_session()
  writer = db_import_writer(db,
                            import_job_id,
                            'storage',
                            phase=0,
                            source='base')
  creds = credentials_from_config(config)
  proxy_builder = make_proxy_builder(*proxy_builder_args)
  proxy = proxy_builder(creds)
  _import_gcp_storage_to_db(proxy, writer, ps, project)
  db.commit()


def import_account_storage_with_pool(pool: f.ProcessPoolExecutor,
                                     import_job_id: int, proxy_builder_args,
                                     ps: PathStack, config) -> List[f.Future]:
  results = []

  def queue_import(path: str, project_id: str) -> f.Future:
    if path == '':
      scope = 'projects/' + project_id
    else:
      scope = path + '/projects/' + project_id
    return pool.submit(_async_proxy, import_job_id, config, proxy_builder_args,
                       ps.scope(scope), project_id)

  for path, project in projects(config['gcp_graph']):
    results.append(queue_import(path, project['projectId']))
  return results


def _import_gcp_storage_to_db(proxy: Proxy, writer: ImportWriter,
                              ps: PathStack, project: str):
  for bucket in _import_gcp_storage(proxy, project):
    writer(ps, 'bucket', bucket)
