import concurrent.futures as f
from typing import Dict, List

from sqlalchemy.orm import Session

from goldfig import ImportWriter, db_import_writer, PathStack
from goldfig.bootstrap_db import import_session
from goldfig.error import GFInternal
from goldfig.gcp import credentials_from_config, walk_graph, ProxyBuilder, make_proxy_builder
from goldfig.gcp.fetch import Proxy, ServiceProxy
from goldfig.models import ImportJob


def _import_gcp_project_iam(v1: ServiceProxy, iam: ServiceProxy,
                            project: str) -> Dict:
  project_data = v1.call_method('projects', 'get', projectId=project)
  iam_policy = v1.call_method('projects', 'getIamPolicy', resource=project)
  project_data['bindings'] = iam_policy.get('bindings', [])
  org_policies = v1.call_method('projects',
                                'listOrgPolicies',
                                resource=f'projects/{project}')
  project_data['policies'] = org_policies.get('policies', [])
  roles = iam.list('projects/roles', view='FULL', parent=f'projects/{project}')
  project_data['roles'] = roles
  #project_data['service_accounts'] = iam.list('projects/serviceAccounts', name=f'projects/{project}')
  project_data['service_accounts'] = []
  service_accounts = iam.list('projects/serviceAccounts',
                              name=f'projects/{project}')
  for service_account in service_accounts:
    policy = iam.call_method('projects/serviceAccounts',
                             'getIamPolicy',
                             resource=service_account['name'])
    service_account['policy'] = policy
    project_data['service_accounts'].append(service_account)
  return project_data


def _import_gcp_folder_iam(v1: ServiceProxy, v2: ServiceProxy,
                           folder: str) -> Dict:
  # technically we don't need this, the graph has all of the folder data
  folder_data = v2.call_method('folders', 'get', name=folder)
  iam_policy = v2.call_method('folders', 'getIamPolicy', resource=folder)
  folder_data['bindings'] = iam_policy.get('bindings', [])
  org_policies = v1.call_method('folders', 'listOrgPolicies', resource=folder)
  folder_data['policies'] = org_policies.get('policies', [])
  return folder_data


def _import_gcp_org_iam(v1: ServiceProxy, iam: ServiceProxy, org: str):
  # technically we don't need this, the graph has all of the org data
  org_data = v1.call_method('organizations', 'get', name=org)
  iam_policy = v1.call_method('organizations', 'getIamPolicy', resource=org)
  org_data['bindings'] = iam_policy.get('bindings', [])
  org_policies = v1.call_method('organizations',
                                'listOrgPolicies',
                                resource=org)
  org_data['policies'] = org_policies.get('policies', [])
  org_data['roles'] = iam.list('organizations/roles', view='FULL', parent=org)
  return org_data


def _import_iam_graph(proxy: Proxy, writer: ImportWriter, ps: PathStack, org,
                      graph):
  assert len(ps._tokens) == 0
  v1 = proxy.service('cloudresourcemanager', 'v1')
  v2 = proxy.service('cloudresourcemanager', 'v2')
  iam = proxy.service('iam', 'v1')
  for typ, entry_path, entry in walk_graph(org, graph):
    if typ == 'organization':
      org_data = _import_gcp_org_iam(v1, iam, entry['name'])
      writer(entry_path, 'organization', org_data)
    elif typ == 'project':
      project_data = _import_gcp_project_iam(v1, iam, entry['projectId'])
      writer(entry_path, 'project', project_data)
    elif typ == 'folder':
      folder_data = _import_gcp_folder_iam(v1, v2, entry['name'])
      writer(entry_path, 'folder', folder_data)
    else:
      raise GFInternal(f'unknown org graph node type: {typ}')


def _async_proxy(import_job_id: int, proxy_builder_args, ps: PathStack,
                 config: Dict, typ: str, name: str, entry_path: str):
  assert len(ps._tokens) == 0
  db = import_session()
  writer = db_import_writer(db, import_job_id, 'iam', phase=0)
  creds = credentials_from_config(config)
  proxy_builder = make_proxy_builder(*proxy_builder_args)
  proxy = proxy_builder(creds)
  if typ == 'organization':
    v1 = proxy.service('cloudresourcemanager', 'v1')
    iam = proxy.service('iam', 'v1')
    org_data = _import_gcp_org_iam(v1, iam, name)
    writer(entry_path, 'organization', org_data)
  elif typ == 'project':
    v1 = proxy.service('cloudresourcemanager', 'v1')
    iam = proxy.service('iam', 'v1')
    project_data = _import_gcp_project_iam(v1, iam, name)
    writer(entry_path, 'project', project_data)
  elif typ == 'folder':
    v1 = proxy.service('cloudresourcemanager', 'v1')
    v2 = proxy.service('cloudresourcemanager', 'v2')
    folder_data = _import_gcp_folder_iam(v1, v2, name)
    writer(entry_path, 'folder', folder_data)
  else:
    raise GFInternal(f'unknown org graph node type: {typ}')
  db.commit()


def import_account_iam_with_pool(pool: f.ProcessPoolExecutor,
                                 import_job_id: int, proxy_builder_args,
                                 ps: PathStack, config) -> List[f.Future]:
  results = []
  org = config['gcp_org']
  graph = config['gcp_graph']

  def queue_import(typ: str, name: str, prefix: str) -> f.Future:
    return pool.submit(_async_proxy, import_job_id, proxy_builder_args, ps,
                       config, typ, name, prefix)

  for typ, prefix, entry in walk_graph(org, graph):
    if typ == 'organization':
      results.append(queue_import(typ, entry['name'], prefix))
    elif typ == 'project':
      results.append(queue_import(typ, entry['projectId'], prefix))
    elif typ == 'folder':
      results.append(queue_import(typ, entry['name'], prefix))
    else:
      raise GFInternal(f'unknown org graph node type: {typ}')
  return results


def import_account_iam_to_db(db: Session, import_job_id: int,
                             proxy_builder: ProxyBuilder):
  import_job = db.query(ImportJob).get(import_job_id)
  writer = db_import_writer(db, import_job.id, 'iam', phase=0)
  creds = credentials_from_config(import_job.configuration)
  proxy = proxy_builder(creds)
  _import_iam_graph(proxy, writer, PathStack.from_import_job(import_job),
                    import_job.configuration['gcp_org'],
                    import_job.configuration['gcp_graph'])
