import concurrent.futures as f
import logging
from typing import Dict, List

from sqlalchemy.orm import Session

from goldfig import ImportWriter, db_import_writer, PathStack
from goldfig.bootstrap_db import import_session
from goldfig.gcp import projects, credentials_from_config, ProxyBuilder, make_proxy_builder
from goldfig.gcp.fetch import Proxy
from goldfig.models import ImportJob

_log = logging.getLogger(__name__)


def _import_gcp_compute(proxy: Proxy, project: str, segment=None):
  # TODO: get Iam Policies where relevant
  sp = proxy.service('serviceusage', 'v1')
  get_result = sp.get(
      'services', name=f'projects/{project}/services/compute.googleapis.com')
  enabled = get_result.get('state', None)
  if enabled != 'ENABLED':
    _log.warning(f'compute disabled for {project}')
    return
  service = proxy.service('compute', 'beta')
  for resource_name in service.resource_names():
    if segment is not None:
      if resource_name < segment[0] or resource_name > segment[1]:
        continue
    resources = service.list(resource_name, project=project)
    _log.info(f'{resource_name} len: {len(resources)}')
    for path, raw in resources:
      yield path, resource_name, raw


def import_account_compute_to_db(db: Session, import_job_id: int,
                                 proxy_builder: ProxyBuilder):
  job: ImportJob = db.query(ImportJob).get(import_job_id)
  writer = db_import_writer(db, job.id, 'compute', phase=0)
  creds = credentials_from_config(job.configuration)
  proxy = proxy_builder(creds)
  graph = job.configuration['gcp_graph']
  # ps = PathStack.from_import_job(job).scope('compute')
  ps = PathStack.from_import_job(job)
  for path, project in projects(graph):
    project_id = project['project_id']
    if path == '':
      scope = 'projects/' + project_id
    else:
      scope = path + '/projects/' + project_id
    _import_compute_to_db(proxy, writer, ps.scope(scope), project_id)


def _async_proxy(import_job_id: int, config: Dict, proxy_builder_args,
                 ps: PathStack, project_id: str, segment):
  db = import_session()
  writer = db_import_writer(db, import_job_id, 'compute', phase=0)
  creds = credentials_from_config(config)
  proxy_builder = make_proxy_builder(*proxy_builder_args)
  proxy = proxy_builder(creds)
  _import_compute_to_db(proxy, writer, ps, project_id, segment)
  db.commit()


def import_account_compute_with_pool(pool: f.ProcessPoolExecutor,
                                     import_job_id: int, proxy_builder_args,
                                     ps: PathStack, config) -> List[f.Future]:
  # ps = ps.scope('compute')
  results = []

  def queue_import(path: str, project_id: str, segment) -> f.Future:
    if path == '':
      scope = 'projects/' + project_id
    else:
      scope = path + '/projects/' + project_id
    return pool.submit(_async_proxy, import_job_id, config, proxy_builder_args,
                       ps.scope(scope), project_id, segment)

  for path, project in projects(config['gcp_graph']):
    # TODO: make this dynamic...
    results.append(
        queue_import(path, project['projectId'],
                     ('acceleratorTypes', 'images')))
    results.append(
        queue_import(path, project['projectId'],
                     ('instanceGroupManagers', 'projects')))
    results.append(
        queue_import(path, project['projectId'],
                     ('regionAutoscalers', 'routers')))
    results.append(
        queue_import(path, project['projectId'], ('routes', 'zones')))
  return results


def _import_compute_to_db(proxy: Proxy,
                          writer: ImportWriter,
                          ps: PathStack,
                          project_id: str,
                          segment=None):
  for path, resource_name, raw in _import_gcp_compute(proxy, project_id,
                                                      segment):
    writer(ps.scope(path), resource_name, raw)


def add_images_to_import(proxy: Proxy, writer: ImportWriter, ps: PathStack,
                         images):
  service = proxy.service('compute', 'beta')
  for image_spec in images:
    project = image_spec['project']
    image_id = image_spec['image_id']
    image = service.get('images', project=project, image=image_id)
    writer(ps.scope(f'organizations/global/projects/{project}'), 'images',
           [image])
