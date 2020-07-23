import os
from typing import Any, Dict, List, Optional

from sqlalchemy import text
from sqlalchemy.orm import Session

from goldfig import ImportWriter, db_import_writer
from goldfig.delta.resource import apply_mapped_attrs, map_relation_deletes, map_resource_deletes, map_resource_prefix, map_resource_relations
from goldfig.error import GFInternal
from goldfig.gcp import Proxy, projects
from goldfig.gcp.compute_adjunct import import_adjunct_data, synthesize_endpoints
from goldfig.gcp.compute_mapper import add_image_attachments
from goldfig.gcp.iam_adjunct import find_and_import_roles
from goldfig.gcp.uri import uri_fn
from goldfig.mapper import DivisionURI, ValueTransforms, Mapper, load_transforms
from goldfig.models import ImportJob


### Mapper functions
def _gcp_tags(tags, **_):
  return tags.get('items', [])


def _zone_from_gcp_url(url: str, **_) -> str:
  parts = url.split('/')
  i = parts.index('zones')
  return parts[i + 1]


def _region_from_zone(zone: str) -> str:
  return '-'.join(zone.split('-')[:-1])


def _region_from_gcp_url(url: str, **kwargs) -> str:
  return _region_from_zone(_zone_from_gcp_url(url))


def _principal_type(uri: str, **kwargs) -> str:
  typ, _ = uri.split(':')
  return typ


def _principal(uri: str, **kwargs) -> str:
  # format is <type>:<principal>
  return uri.split(':')[1]


def _metadata_to_tags(metadata: Optional[List[Dict[str, str]]], **_):
  if metadata is None:
    return {}
  return {f'metadata:{entry["key"]}': entry['value'] for entry in metadata}


def make_iam_binding_fn(graph: Dict[str, Any], org_id: str):
  prefix = f'organizations/{org_id}'
  remove_org = lambda s: s[len(prefix) + 1:]

  def _full_parent(parent: str) -> str:
    if parent.startswith('organizations/'):
      return remove_org(parent)
    elif parent.startswith('projects/'):
      project_id = parent[len('projects/'):]
      for path, projects in graph['projects'].items():
        for project in projects:
          if project['projectId'] == project_id:
            removed = remove_org(path)
            if removed == '':
              return parent
            else:
              return f'{removed}/{parent}'
    elif parent.startswith('folders/'):
      folder_id = parent
      for path, folders in graph['folders'].items():
        for folder in folders:
          if folder['name'] == folder_id:
            removed = remove_org(path)
            if removed == '':
              return parent
            else:
              return f'{removed}/{parent}'
    raise GFInternal(f'Unknown parent uri for iam binding {parent} {graph}')

  def iam_binding(parent_uri, target_raw, **kwargs):
    # for a binding, we want:
    # path of parent as attr
    # resource = principal
    # target = role
    # relation = can-use
    parent_path = _full_parent(parent_uri)
    role = target_raw['role']
    members = target_raw['members']
    for member in members:
      resource_uri = f'{parent_path}${member}'
      target_uri = role
      attrs = []
      relation = 'can-use'
      yield resource_uri, relation, target_uri, attrs

  return iam_binding


### End Mapper functions

GCP_MAPPER_FNS: ValueTransforms = {
    'gcp_tags': _gcp_tags,
    'gcp_zone': _zone_from_gcp_url,
    'gcp_region': _region_from_gcp_url,
    'gcp_principal_type': _principal_type,
    'gcp_principal_id': _principal,
    'gcp_metadata': _metadata_to_tags
}


def _map_principals(db: Session, import_job: ImportJob):
  stmt = text('''
    SELECT
      RI.path as path,
      Members AS member
    FROM
      raw_import AS RI,
      jsonb_array_elements(RI.raw->'bindings') AS Bindings,
      jsonb_array_elements(Bindings->'members') AS Members
    WHERE
      RI.import_job_id = :import_job_id
      AND RI.resource_name in ('project', 'folder', 'organization')
  ''')
  results = db.execute(stmt, {'import_job_id': import_job.id})
  for row in results:
    path = row['path']
    # Take the last path segment since it's the path
    # into the org
    uri_path = path.split('$')[-1]
    member = row['member']
    apply_mapped_attrs(db,
                       import_job,
                       path,
                       mapped={
                           'name': member,
                           'category': 'Policy',
                           'provider_type': None,
                           'raw': member,
                           'uri': f'{uri_path}${member}',
                           'service': 'iam'
                       },
                       attrs=[{
                           'type': 'Principal',
                           'name': 'Type',
                           'value': _principal_type(member)
                       }, {
                           'type': 'Principal',
                           'name': 'Identity',
                           'value': _principal(member)
                       }, {
                           'type': 'Principal',
                           'name': 'Tier',
                           'value': 'division'
                       }, {
                           'type': 'Principal',
                           'name': 'Scoped',
                           'value': True
                       }],
                       raw_import_id=None)


def _gcp_not_in_org(graph):
  org_projects = [project for _, project in projects(graph)]

  def not_in_org(uri: str, **kwargs) -> bool:
    parts = uri.split('/')
    project_index = parts.index('projects')
    project = parts[project_index + 1]
    return project not in org_projects

  return not_in_org


class GCPDivisionURI(DivisionURI):
  def __init__(self, org_id: str):
    self._org_id = org_id

  def uri_for_path(self, path: str) -> str:
    if path == '$':
      return 'global'
    else:
      # Take first chunk, the rest is region and other uninteresting stuff
      org_path = path.split('$')[0]
      segments = org_path.split('/')
      if len(segments) >= 2:
        if segments[0] == 'organizations' and segments[1] == 'global':
          return 'global'
        if segments[-2] == 'projects':
          return '/'.join(segments[-2:])
        raise GFInternal(f'Unknown path in uri_for_path: {org_path}')
      else:
        # Contained directly in the organization
        return f'organizations/{self._org_id}'

  def uri_for_parent(self, path: str) -> str:
    segments = path.split('/')
    assert len(segments) % 2 == 0
    assert len(segments) >= 2
    parent_path = segments[:-2]
    if len(parent_path) == 0:
      # this is contained in the organization
      return f'organizations/{self._org_id}'
    else:
      return '/'.join(parent_path[-2:])


def map_import(db: Session, import_job: ImportJob, proxy: Proxy):
  assert import_job.path_prefix == ''
  org_id = import_job.configuration['account']['account_id']
  division_uri = GCPDivisionURI(org_id)
  extra_fns = GCP_MAPPER_FNS.copy()
  extra_fns['gcp_binding'] = make_iam_binding_fn(
      import_job.configuration['gcp_graph'], org_id)
  extra_fns['gcp_not_in_org'] = _gcp_not_in_org(
      import_job.configuration['gcp_graph'])
  transform_path = os.path.join(os.path.dirname(__file__), 'transforms')
  transforms = load_transforms(transform_path)
  mapper = Mapper(transforms,
                  import_job.provider_account_id,
                  division_uri,
                  extra_fns=extra_fns)
  map_resource_prefix(db, import_job, import_job.path_prefix, mapper, uri_fn)

  # IAM additional work
  _map_principals(db, import_job)
  iam_writer = db_import_writer(db, import_job.id, 'iam', phase=1)
  find_and_import_roles(db, proxy, iam_writer, import_job)

  # Compute additional work
  # TODO: rename and make proper imports
  import_adjunct_data(db, import_job, proxy)
  synthesize_endpoints(db, import_job)
  # map agin, to get anything we added
  map_resource_prefix(db, import_job, import_job.path_prefix, mapper, uri_fn)

  # Now map deletes
  map_resource_deletes(db, import_job.path_prefix, import_job, service=None)

  found_relations = map_resource_relations(db, import_job,
                                           import_job.path_prefix, mapper,
                                           uri_fn)
  found_synthetic = add_image_attachments(db, import_job.provider_account_id)
  map_relation_deletes(db, import_job, import_job.path_prefix,
                       found_relations.union(found_synthetic))
