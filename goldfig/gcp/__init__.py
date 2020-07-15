import concurrent.futures as f
import json
import logging
import os
import subprocess
import textwrap
from typing import Callable, Dict, Generator, List, Optional, Tuple

import googleapiclient.errors
from google.oauth2 import credentials
from sqlalchemy.orm import Session
from sqlalchemy.orm.attributes import flag_modified

from goldfig import collect_exceptions, PathStack, db_import_writer
from goldfig.error import GFError
from goldfig.gcp.fetch import Proxy
from goldfig.models import ImportJob, ProviderAccount

ProxyBuilder = Callable[[credentials.Credentials], Proxy]

_log = logging.getLogger(__name__)


def make_proxy_builder(use_cache: bool = False,
                       patch_id: Optional[int] = None) -> ProxyBuilder:
  def _fn(creds: credentials.Credentials) -> Proxy:
    if use_cache:
      return Proxy.build(creds, patch_id=patch_id)
    else:
      return Proxy.dummy(creds)

  return _fn


def get_gcloud_output(*args):
  result = subprocess.run(['gcloud', *args],
                          stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE,
                          text=True)
  return result.stdout


def get_gcloud_auth_var(*args) -> str:
  return get_gcloud_output('auth', *args)


def get_gcloud_credentials() -> Tuple[str, str]:
  # TODO: get refresh token and stuff like that
  id_token = get_gcloud_auth_var('print-identity-token').strip()
  access_token = get_gcloud_auth_var('print-access-token').strip()
  return id_token, access_token


def get_gcloud_info():
  info = get_gcloud_output('info', '--format="json"')
  return json.loads(info)


def get_gcloud_user() -> str:
  gcloud_info = get_gcloud_info()
  return gcloud_info['config']['account']


def get_org_graph(org_id: str, proxy: Proxy, principal: str):
  v1_service = proxy.service('cloudresourcemanager', 'v1')
  projects = v1_service.list('projects')
  v2_service = proxy.service('cloudresourcemanager', 'v2')

  by_parent = {}
  has_folder = False
  for project in projects:
    if 'parent' not in project:
      _log.warn(
          f'Skipping project {project["projectId"]} because it is not in the organization'
      )
      continue
    parent = project['parent']['type'] + 's/' + project['parent']['id']
    has_folder |= parent.startswith('folders/')
    tier_projects = by_parent.get(parent, [])
    tier_projects.append(project)
    by_parent[parent] = tier_projects

  folder_paths = {}
  project_paths = {}

  def build_graph(parent: str, path):
    next_path = [*path, parent]
    path_str = '/'.join(next_path)
    projects_at_path = by_parent.pop(parent, None)
    if projects_at_path is not None:
      project_paths[path_str] = projects_at_path
    try:
      folders = v2_service.list('folders', parent=parent)
    except googleapiclient.errors.HttpError as err:
      if err.resp.status == 403:
        if has_folder:
          msg = textwrap.dedent(
              f'''The credentials supplied do not have the resourcemanager.folders.list permission.
            However, some of the projects to be imported appear to be in folders.
            Consider adding an iam-policy-binding for this user to the organization root for
            the role roles/resourcemanager.folderViewer

            e.g.
            gcloud organizations add-iam-policy-binding {org_id} --member=user:{principal} --role=roles/resourcemanager.folderViewer
          ''')
          raise GFError(msg)
        else:
          # We don't know of any projects in folders,
          # and we can't see any folders. Ignore them
          # and assume everything is at top-level
          folders = []
      else:
        raise err
    if len(folders) > 0:
      folder_paths[path_str] = folders
    for folder in folders:
      build_graph(folder['name'], path=next_path)

  # TODO: include top-level, empty-path entry for org?
  build_graph(f'organizations/{org_id}', [])
  return folder_paths, project_paths


def credentials_from_config(configuration) -> credentials.Credentials:
  id_token = configuration['credentials']['id_token']
  access_token = configuration['credentials']['access_token']
  return credentials.Credentials(access_token, id_token=id_token)


def add_graph_to_import_job(db: Session, import_job_id: int,
                            proxy_builder: ProxyBuilder):
  job = db.query(ImportJob).get(import_job_id)
  configuration = job.configuration
  creds = credentials_from_config(configuration)
  proxy = proxy_builder(creds)
  org_id = configuration['account']['account_id']
  folder_paths, project_paths = get_org_graph(
      org_id, proxy, configuration['principal']['provider_id'])
  configuration['gcp_graph'] = {
      'folders': folder_paths,
      'projects': project_paths
  }
  job.configuration = configuration
  # TODO: may not be needed for later version of postgres
  flag_modified(job, 'configuration')
  db.add(job)
  _log.info(f'adding to {import_job_id} {job.configuration}')


def add_account_interactive(db: Session, org_id: str, org_name: str,
                            force: bool) -> ProviderAccount:
  # TODO: this is dumb, and results in circular dependencies
  from goldfig.cli.util import query_yes_no
  add = force or query_yes_no(
      f'Add GCP organization {org_name} ({org_id}) to GoldFig?')
  if not add:
    raise GFError('User cancelled account addition')
  provider = ProviderAccount(provider='gcp', name=org_id)
  db.add(provider)
  db.flush()
  return provider


def build_gcloud_import_job(proxy_builder: ProxyBuilder) -> Dict:
  id_token, access_token = get_gcloud_credentials()
  user = get_gcloud_user()

  creds = credentials.Credentials(access_token, id_token=id_token)
  proxy = proxy_builder(creds)

  service = proxy.service('cloudresourcemanager', 'v1')
  result = service.call_method('organizations', 'search')
  orgs = result.get('organizations', [])
  if len(orgs) != 1:
    orgs_str = '\n'.join([org['displayName'] for org in orgs])
    msg = 'Credentials beloing to more than one organization is currently unsupported. Found organizations:\n' + orgs_str
    raise GFError(msg)
  org = orgs[0]
  org_id = org['name'].split('/')[1]
  import_job = {
      'account': {
          'account_id': org_id,
          'provider': 'gcp'
      },
      'credentials': {
          'id_token': id_token,
          'access_token': access_token
      },
      'principal': {
          'provider_id': user,
          'provider_uri': user
      },
      'gcp_org': org
  }
  return import_job


def projects(graph) -> Generator[Tuple[str, Dict], None, None]:
  # TODO: path should be full path to the project
  project_paths = graph['projects']
  drop_org = lambda s: '/'.join(s.split('/')[2:])
  for path, projects in project_paths.items():
    for project in projects:
      yield drop_org(path), project


def walk_graph(org, graph) -> Generator[Tuple[str, str, Dict], None, None]:
  projects = graph['projects']
  org_name = org['name']
  # add 1 to account for trailing /
  org_name_len = len(org_name) + 1
  yield 'organization', '', org
  for project in projects.get(org_name, []):
    yield 'project', f'projects/{project["projectId"]}', project
  for prefix, folders in graph['folders'].items():
    for folder in folders:
      in_org_prefix = prefix[org_name_len:]
      if in_org_prefix == '':
        folder_path = folder['name']
      else:
        folder_path = f'{in_org_prefix}/{folder["name"]}'
      yield 'folder', folder_path, folder
      graph_folder_path = '/'.join([prefix, folder['name']])
      for project in projects.get(graph_folder_path, []):
        yield 'project', f'{folder_path}/projects/{project["projectId"]}', project


def run_single_session(db: Session, import_job_id: int,
                       proxy_builder: ProxyBuilder):
  from goldfig.gcp.compute import import_account_compute_to_db
  from goldfig.gcp.iam import import_account_iam_to_db
  from goldfig.gcp.storage import import_account_storage_to_db
  add_graph_to_import_job(db, import_job_id, proxy_builder)
  db.flush()
  import_account_iam_to_db(db, import_job_id, proxy_builder)
  db.flush()
  import_account_storage_to_db(db, import_job_id, proxy_builder)
  db.flush()
  import_account_compute_to_db(db, import_job_id, proxy_builder)


def run_parallel_session(import_job: ImportJob,
                         proxy_builder_args) -> List[str]:
  '''
  :return: A list of formatted exceptions that were thrown
  '''
  from goldfig.gcp.compute import import_account_compute_with_pool
  from goldfig.gcp.iam import import_account_iam_with_pool
  from goldfig.gcp.storage import import_account_storage_with_pool
  workers = max(1, os.cpu_count() - 1)
  # db.flush()
  # import_job: ImportJob = db.query(ImportJob).get(import_job_id)
  ps = PathStack.from_import_job(import_job)
  org = import_job.configuration['gcp_org']
  graph = import_job.configuration['gcp_graph']
  with f.ProcessPoolExecutor(max_workers=workers) as pool:
    results = import_account_iam_with_pool(pool, import_job.id,
                                           proxy_builder_args, ps,
                                           import_job.configuration)
    results += import_account_storage_with_pool(pool, import_job.id,
                                                proxy_builder_args, ps,
                                                import_job.configuration)
    results += import_account_compute_with_pool(pool, import_job.id,
                                                proxy_builder_args, ps,
                                                import_job.configuration)
    f.wait(results)
    return collect_exceptions(results)


def map_import(db: Session, import_job_id: int, proxy_builder: ProxyBuilder):
  from goldfig.gcp.map import map_import as library_map_import
  import_job: ImportJob = db.query(ImportJob).get(import_job_id)
  creds = credentials_from_config(import_job.configuration)
  proxy = proxy_builder(creds)
  writer = db_import_writer(db, import_job_id, phase=1)
  library_map_import(db, import_job, proxy, writer)
