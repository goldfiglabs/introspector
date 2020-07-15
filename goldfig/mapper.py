from functools import partial
import json
import logging
import os
from typing import Any, Callable, Dict, List, Optional, Union
import yaml

import jmespath

from goldfig.error import GFError, GFInternal

_log = logging.getLogger(__name__)

ValueTransform = Callable[[Any], Any]
ValueTransforms = Dict[str, ValueTransform]


def load_transform_schema():
  schema_path = os.path.join(os.path.dirname(__file__),
                             'transform_schema.json')
  with open(schema_path, 'r') as f:
    schema = json.load(f)
  return schema


def _load_json_transform(file_path: str):
  with open(file_path, 'r') as f:
    text = f.read()
  return json.loads(text)


def _load_yaml_transform(file_path: str):
  with open(file_path, 'r') as f:
    return yaml.safe_load(f)


def load_transforms(path: str):
  transforms = {}
  for filename in os.listdir(path):
    if filename.endswith('.json'):
      _log.debug(f'Found json {filename}')
      key = filename[:-len('.json')]
      transforms[key] = _load_json_transform(os.path.join(path, filename))
    elif filename.endswith('.yml'):
      _log.debug(f'Found yaml {filename}')
      key = filename[:-len('.yml')]
      transforms[key] = _load_yaml_transform(os.path.join(path, filename))
  return transforms


def _find_path(path: str,
               raw: Any,
               require_string_on_empty: bool = False) -> Any:
  if path == '':
    if require_string_on_empty and not isinstance(raw, str):
      raise GFError(
          f'Transform error: Empty path, but raw is {raw}. Expected a string')
    return raw
  else:
    return jmespath.search(path, raw)


def string_to_float(s: str, **_) -> float:
  return float(s)  # return 0 if typeerror, overflow, or inf?


BUILTIN_FNS: Dict[str, ValueTransform] = {'string_to_float': string_to_float}


class DivisionURI:
  def uri_for_path(self, path: str) -> str:
    raise NotImplementedError('abstract')

  def uri_for_parent(self, path: str) -> str:
    raise NotImplementedError('abstract')


class Mapper:
  def __init__(self,
               transforms,
               provider_account_id: int,
               division_uri: DivisionURI,
               extra_fns: Optional[ValueTransforms] = None,
               extra_attrs=None):
    self._transforms = transforms
    self.provider_account_id = provider_account_id
    fns = BUILTIN_FNS.copy()
    fns.update(extra_fns or {})
    self._fns: ValueTransforms = fns
    self._extra_attrs = extra_attrs
    self._division_uri = division_uri

  def fn(self, name: str) -> ValueTransform:
    return self._fns[name]

  def value_from_spec(self, spec, raw, parent=None, ctx=None) -> Any:
    value: Any = None
    if 'items' in spec:
      value = []
      for subspec in spec['items']:
        sub_result = self.value_from_spec(subspec, raw, parent=parent)
        value.extend(sub_result)
    elif 'context' in spec:
      path = spec['context']
      if ctx is None:
        value = None  # error?
      else:
        value = jmespath.search(path, ctx)
    elif 'dict' in spec:
      value = {}
      for subspec in spec['dict']:
        sub_result = self.value_from_spec(subspec, raw, parent=parent)
        if sub_result is not None:
          value = {**value, **sub_result}
    elif 'identity' in spec:
      path = spec['identity']
      value = jmespath.search(path, raw)
    elif 'path' in spec:
      path = spec['path']
      if path == '':
        value = raw
      else:
        value = jmespath.search(path, raw)
    elif parent is not None and 'parent_path' in spec:
      path = spec['parent_path']
      value = jmespath.search(path, parent)
    elif 'value' in spec:
      path = None
      value = spec['value']
    if 'transform' in spec:
      # TODO: check if generator, yield as appropriate?
      transform = self.fn(spec['transform'])
      value = transform(value)
    if value is None and 'default' in spec:
      value = spec['default']
    return value

  def _find_transform(self, resource_name: str):
    transform = self._transforms.get(resource_name)
    if transform is None:
      _log.debug(f'No transform for {resource_name}')
      return {}
    else:
      return transform

  def _map_provider_attrs(self, attr_names: List[Union[str, Dict]], raw):
    attrs = []
    for attr_name in attr_names:
      if isinstance(attr_name, str):
        value = self.value_from_spec({'path': attr_name}, raw)
        if value is not None:
          attrs.append({'type': 'provider', 'name': attr_name, 'value': value})
      elif isinstance(attr_name, dict):
        for path_segment, keys in attr_name.items():
          for key in keys:
            path = '.'.join([path_segment, key])
            value = self.value_from_spec({'path': path}, raw)
            # Note that this flattens the namespace
            attrs.append({'type': 'provider', 'name': key, 'value': value})
      else:
        raise GFInternal(f'unknown attr_name {attr_name}')
    return attrs

  def _map_custom_attrs(self, attrs_spec, category, raw, ctx):
    attrs = []
    for typ, attr_specs in attrs_spec.items():
      if typ == '_':
        resource_type = category
      else:
        resource_type = typ
      for name, attr_spec in attr_specs.items():
        value = self.value_from_spec(attr_spec, raw, ctx=ctx)
        if value is not None:
          attrs.append({'type': resource_type, 'name': name, 'value': value})
    return attrs

  def _apply_uri_paths(self, uri_paths: Dict[str, str], raw) -> Dict[str, str]:
    args = {}
    for key, path in uri_paths.items():
      args[key] = _find_path(path, raw)
    return args

  def _map_resource_v1(self, uri_paths: Dict, name_path: str,
                       category: Optional[str], provider_type: str,
                       service: str, uri_fn: Callable, raw, ctx):
    name = _find_path(name_path, raw, require_string_on_empty=True)
    uri_args = self._apply_uri_paths(uri_paths, raw)
    try:
      uri = uri_fn(**uri_args, service=service, context=ctx)
    except:
      _log.error(f'URI fn failed with args {uri_args}')
      raise
    return {
        'name': name,
        'provider_type': provider_type,
        'raw': raw,
        'uri': uri,
        'category': category,
        'service': service
    }

  def _map_spec_v1(
      self,
      spec,
      raw_list: List[Any],
      ctx,
      resource_name: str,
      raw_uri_fn: Callable,
      parent_kwargs: Dict  # TODO: rename to context?
  ):
    resource_name = spec.get('resource_name', resource_name)
    uri_fn = partial(raw_uri_fn, resource_name=resource_name, **parent_kwargs)
    category = spec.get('category')
    provider_type = spec.get('provider_type')
    service = spec['service']
    uri_paths = spec.get('uri')
    name_path = spec.get('name')
    attr_specs = spec.get('attributes', {})
    provider_attr_spec = attr_specs.get('provider', [])
    custom_attr_spec = attr_specs.get('custom', {})
    for raw in raw_list:
      resource = self._map_resource_v1(uri_paths, name_path, category,
                                       provider_type, service, uri_fn, raw,
                                       ctx)
      provider_attrs = self._map_provider_attrs(provider_attr_spec, raw)
      custom_addrs = self._map_custom_attrs(custom_attr_spec, category, raw,
                                            ctx)
      yield resource, provider_attrs + custom_addrs

  def _map_resources_v1(self,
                        raw_list: List[Any],
                        ctx,
                        resource_name: str,
                        raw_uri_fn: Callable,
                        parent_args: Optional[Dict] = None):
    # TODO: validate?
    transform = self._find_transform(resource_name)
    version = transform.get('version', 0)
    if version != 1:
      raise GFInternal(
          f'v1 mapper called for {resource_name} with version {version}')
    parent_kwargs = {} if parent_args is None else parent_args
    resource_specs = transform.get('resources', [])
    for spec in resource_specs:
      yield from self._map_spec_v1(spec, raw_list, ctx, resource_name,
                                   raw_uri_fn, parent_kwargs)
    subspecs = transform.get('subresources', [])
    for spec in subspecs:
      subresource_key = spec.get('key')
      subresource_name = spec.get('type')
      parent_params_spec = spec.get('parent', {})
      for parent in raw_list:
        subresources = parent[subresource_key]
        parent_params = {
            k: self.value_from_spec(v, parent, parent=parent_args)
            for k, v in parent_params_spec.items()
        }
        yield from self._map_resources_v1(subresources,
                                          ctx,
                                          subresource_name,
                                          partial(
                                              raw_uri_fn,
                                              resource_name=subresource_name),
                                          parent_args=parent_params)

  def map_resources(self,
                    raw_list: List[Any],
                    ctx: Optional[Dict],
                    resource_name: str,
                    raw_uri_fn: Callable,
                    parent_args: Optional[Dict] = None):
    transform = self._find_transform(resource_name)
    version = transform.get('version', 0)
    if version >= 1:
      yield from self._map_resources_v1(raw_list, ctx, resource_name,
                                        raw_uri_fn, parent_args)

  def _map_spec_relations_v1(self, spec, uri_fn, uri_args, raw,
                             parent_kwargs: Dict):
    relation_specs = spec.get('relations', [])
    service = spec['service']
    try:
      source_uri = uri_fn(**uri_args, **parent_kwargs, service=spec['service'])
    except:
      # Some resources (AWS images, for one) do not contain
      # enough info for a full uri, and so will throw here.
      # However, they also don't have relations, so we can
      # short-circuit and return without missing anything
      if len(relation_specs
             ) == 0 and service == 'ec2' and spec['provider_type'] == 'Image':
        return
      raise
    category = spec.get('category', '')
    # HACK: passed in uri args is a bad way to do this
    path = uri_args['path']
    yield from self._map_in_relation(path, category, source_uri)
    for relation_spec in relation_specs:
      yield from self._map_relation(relation_spec, source_uri, uri_args,
                                    uri_fn, raw, parent_kwargs, service)

  def _map_in_relation(self, path: str, category: str, resource_uri: str):
    if category == 'Organization':
      # Orgs are not in anything
      return
    elif category == 'Division':
      division_uri = self._division_uri.uri_for_parent(path)
    else:
      division_uri = self._division_uri.uri_for_path(path)
    yield resource_uri, 'in', division_uri, []

  def _map_relation_spec_v1(self, spec, path: str, raw_list,
                            resource_name: str, raw_uri_fn,
                            parent_args: Optional[Dict]):
    resource_name = spec.get('resource_name', resource_name)
    parent_kwargs = {} if parent_args is None else parent_args
    for raw in raw_list:
      uri_args = self._uri_args(spec, raw)
      uri_args['path'] = path
      uri_args['resource_name'] = resource_name
      yield from self._map_spec_relations_v1(spec, raw_uri_fn, uri_args, raw,
                                             parent_kwargs)

  def _map_relations_v1(self,
                        path: str,
                        raw_list,
                        resource_name: str,
                        raw_uri_fn,
                        parent_args: Optional[Dict] = None):
    # TODO: validate?
    transform = self._find_transform(resource_name)
    version = transform.get('version', 0)
    if version != 1:
      raise GFInternal(
          f'v1 mapper called for {resource_name} with version {version}')
    resource_specs = transform.get('resources', [])
    for spec in resource_specs:
      yield from self._map_relation_spec_v1(spec, path, raw_list,
                                            resource_name, raw_uri_fn,
                                            parent_args)
    subspecs = transform.get('subresources', [])
    for spec in subspecs:
      subresource_key = spec.get('key')
      subresource_name = spec.get('type')
      parent_params_spec = spec.get('parent', {})
      for parent in raw_list:
        subresources = parent[subresource_key]
        parent_params = {
            k: self.value_from_spec(v, parent, parent=parent_args)
            for k, v in parent_params_spec.items()
        }
        yield from self.map_relations(path,
                                      subresources,
                                      subresource_name,
                                      partial(raw_uri_fn,
                                              resource_name=subresource_name),
                                      parent_args=parent_params)

  def map_relations(self,
                    path: str,
                    raw_list,
                    resource_name: str,
                    raw_uri_fn,
                    parent_args: Optional[Dict] = None):
    # TODO: ctx for uris?
    # TODO: document hierarchy of args for uri fns
    transform = self._find_transform(resource_name)
    version = transform.get('version', 0)
    if version >= 1:
      yield from self._map_relations_v1(path, raw_list, resource_name,
                                        raw_uri_fn, parent_args)

  def _map_relation(self, relation_spec, parent_uri, uri_args, uri_fn, raw,
                    parent_args, service: str):
    # TODO: This feature is a hack / escape hatch for hard-to-model relations
    fn_name = relation_spec.get('fn')
    if fn_name is not None:
      fn = self.fn(fn_name)
    else:
      fn = None
    invert = relation_spec.get('invert', False)
    relation = relation_spec.get('relation')
    targets = jmespath.search(relation_spec['path'], raw) or []
    if not isinstance(targets, list):
      targets = [targets]
    for target in targets:
      if fn is not None:
        yield from fn(parent_uri=parent_uri,
                      target_raw=target,
                      uri_args=uri_args,
                      parent_raw=raw,
                      parent_args=parent_args)
        continue
      target_args = {'parent_uri': uri_args.copy()}
      for key, spec in relation_spec['uri'].items():
        value = self.value_from_spec(spec, target, parent=raw)
        target_args[key] = value
      try:
        target_uri = uri_fn(**target_args, **parent_args, service=service)
      except:
        _log.error(f'URI failed {target_args}, {parent_args}, {service}')
        raise
      attrs = []
      for key, spec in relation_spec.get('attributes', {}).items():
        value = self.value_from_spec(spec, target)
        attrs.append({'name': key, 'value': value})
      if invert:
        yield target_uri, relation, parent_uri, attrs
      else:
        yield parent_uri, relation, target_uri, attrs

  def _uri_args(self, transform, raw):
    kwargs = {}
    for key, path in transform.get('uri', {}).items():
      kwargs[key] = _find_path(path, raw)
    return kwargs
