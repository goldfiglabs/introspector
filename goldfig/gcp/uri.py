from goldfig.error import GFInternal

# TODO: document these fns


def _iam_uri(**kwargs):
  leaf = kwargs['leaf']
  segments = []
  parent_resource = kwargs.get('parent_resource')
  if parent_resource is not None:
    segments.append(parent_resource)
  if 'parent_segment' in kwargs:
    segments.append(kwargs['parent_segment'])
  if kwargs.get('resource_name') == 'project':
    segments.append('projects')
  elif kwargs.get('resource_name') == 'principal':
    segments.append('principals')
  segments.append(leaf)
  return '/'.join(segments)


def _scope_from_path(path: str) -> str:
  # 0 -> path!
  return path.split('$')[0]


def _compute_uri(**kwargs) -> str:
  resource_name = kwargs.get('resource_name')
  if resource_name == 'scoped_principal':
    id = kwargs['principal_id']
    typ = kwargs['principal_type']
    principal = f'{typ}:{id}'
    prefix = _scope_from_path(kwargs['parent_uri']['path'])
    uri = f'{prefix}${principal}'
    return uri
  raise GFInternal(f'Failed to find compute uri {kwargs}')


def uri_fn(service: str, **kwargs) -> str:
  uri = kwargs.get('uri')
  if uri is not None:
    return uri
  if service == 'storage':
    raise GFInternal(f'Storage uri missing "uri" arg {kwargs}')
  elif service == 'iam':
    return _iam_uri(**kwargs)
  elif service == 'cloudresourcemanager':
    return _iam_uri(**kwargs)
  elif service == 'compute':
    return _compute_uri(**kwargs)
  raise GFInternal(f'Unknown service {service} for uri, args {kwargs}')
