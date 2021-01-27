from dataclasses import dataclass, asdict
from functools import partial
import json
import logging
import os
from typing import Any, Callable, Dict, Iterator, List, Optional, Tuple, Union
import yaml

import jmespath

from goldfig.error import GFError, GFInternal
from goldfig.models.resource import Uri, UriFn

_log = logging.getLogger(__name__)

ValueTransform = Callable[[Any], Any]
ValueTransforms = Dict[str, ValueTransform]

Context = Dict[str, str]


@dataclass
class MappedResource:
  name: str
  provider_type: Optional[str]
  raw: Any
  uri: str
  category: Optional[str]
  service: str


@dataclass
class MappedAttribute:
  type: str
  name: str
  value: Any

  def as_dict(self):
    return asdict(self)


MapResult = Tuple[MappedResource, List[MappedAttribute]]


@dataclass
class Partial:
  target_uri: str
  raw: Any
  attrs: List[MappedAttribute]


@dataclass
class ResourceSpec:
  resource_name: Optional[str]
  category: Optional[str]
  provider_type: Optional[str]
  uri: Dict
  name: Union[str, Dict[str, str]]
  attributes: Dict


@dataclass
class SubResourceSpec:
  key: str
  typ: str
  parent: Dict[str, Any]


@dataclass
class PartialSpec:
  uri: Dict
  attributes: Dict


@dataclass
class Transform:
  service: str
  spec: Any

  @property
  def version(self) -> int:
    return self.spec.get('version', 0)

  @property
  def resources(self) -> Iterator[ResourceSpec]:
    for spec in self.spec.get('resources', []):
      yield ResourceSpec(resource_name=spec.get('resource_name'),
                         category=spec.get('category'),
                         provider_type=spec.get('provider_type'),
                         uri=spec['uri'],
                         name=spec['name'],
                         attributes=spec.get('attributes', {}))

  @property
  def subresources(self) -> Iterator[SubResourceSpec]:
    for spec in self.spec.get('subresources', []):
      yield SubResourceSpec(key=spec['key'],
                            typ=spec['type'],
                            parent=spec.get('parent', {}))

  @property
  def partials(self) -> Iterator[PartialSpec]:
    for spec in self.spec.get('partials', []):
      yield PartialSpec(uri=spec['uri'], attributes=spec['attributes'])


Transforms = Dict[str, Dict[str, Transform]]


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


def load_transforms(path: str) -> Transforms:
  transforms = {}
  for dirname in os.listdir(path):
    dir_path = os.path.join(path, dirname)
    if os.path.isdir(dir_path):
      service = dirname
      service_transforms = transforms.get(service, {})
      for filename in os.listdir(dir_path):
        full_path = os.path.join(dir_path, filename)
        if filename.endswith('.json'):
          _log.debug(f'Found json {service}/{filename}')
          key = filename[:-len('.json')]
          spec = _load_json_transform(full_path)
        elif filename.endswith('.yml'):
          _log.debug(f'Found yaml {filename}')
          key = filename[:-len('.yml')]
          spec = _load_yaml_transform(full_path)
        else:
          continue
        service_transforms[key] = Transform(service, spec)
      transforms[service] = service_transforms
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
               transforms: Transforms,
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
    try:
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
    except Exception as e:
      _log.exception(
          f'Value mapping failed Spec={spec} raw={raw} parent={parent} ctx={ctx}'
      )
      raise

  def _find_transform(self, service: str, resource_name: str) -> Transform:
    service_transforms = self._transforms.get(service, {})
    transform = service_transforms.get(resource_name)
    if transform is None:
      _log.debug(f'No transform for {resource_name}')
      return Transform(service, {})
    else:
      return transform

  def _map_provider_attrs(self, attr_names: List[Union[str, Dict]],
                          raw) -> List[MappedAttribute]:
    attrs: List[MappedAttribute] = []
    for attr_name in attr_names:
      if isinstance(attr_name, str):
        value = self.value_from_spec({'path': attr_name}, raw)
        if value is not None:
          attrs.append(
              MappedAttribute(type='provider', name=attr_name, value=value))
      elif isinstance(attr_name, dict):
        for path_segment, keys in attr_name.items():
          for key in keys:
            path = '.'.join([path_segment, key])
            value = self.value_from_spec({'path': path}, raw)
            # Note that this flattens the namespace
            attrs.append(
                MappedAttribute(type='provider', name=key, value=value))
      else:
        raise GFInternal(f'unknown attr_name {attr_name}')
    return attrs

  def _map_custom_attrs(self, attrs_spec, category, raw,
                        ctx) -> List[MappedAttribute]:
    attrs: List[MappedAttribute] = []
    for typ, attr_specs in attrs_spec.items():
      if typ == '_':
        resource_type = category
      else:
        resource_type = typ
      for name, attr_spec in attr_specs.items():
        value = self.value_from_spec(attr_spec, raw, ctx=ctx)
        if value is not None:
          attrs.append(
              MappedAttribute(type=resource_type, name=name, value=value))
    return attrs

  def _map_resource_v1(self, spec: ResourceSpec, service: str,
                       uri_fn: Callable, raw, ctx) -> MappedResource:
    if isinstance(spec.name, str):
      name = _find_path(spec.name, raw, require_string_on_empty=True)
    else:
      name = spec.name['value']
    uri_args = {key: _find_path(path, raw) for key, path in spec.uri.items()}
    try:
      uri = uri_fn(**uri_args, service=service, context=ctx)
    except:
      _log.error(f'URI fn failed with args {uri_args}')
      raise
    return MappedResource(name=name,
                          provider_type=spec.provider_type,
                          raw=raw,
                          uri=uri,
                          category=spec.category,
                          service=service)

  def _map_spec_v1(self, service: str, spec: ResourceSpec, raw_list: List[Any],
                   ctx: Context, resource_name: str, raw_uri_fn: Callable,
                   parent_kwargs: Dict) -> Iterator[MapResult]:
    if spec.resource_name is not None:
      resource_name = spec.resource_name
    uri_fn = partial(raw_uri_fn, resource_name=resource_name, **parent_kwargs)
    provider_attr_spec = spec.attributes.get('provider', [])
    custom_attr_spec = spec.attributes.get('custom', {})
    for raw in raw_list:
      resource = self._map_resource_v1(spec, service, uri_fn, raw, ctx)
      provider_attrs = self._map_provider_attrs(provider_attr_spec, raw)
      custom_addrs = self._map_custom_attrs(custom_attr_spec, spec.category,
                                            raw, ctx)
      yield resource, provider_attrs + custom_addrs

  def _map_resources_v1(
      self,
      raw_list: List[Any],
      ctx: Context,
      service: str,
      resource_name: str,
      raw_uri_fn: Callable,
      parent_args: Optional[Dict] = None) -> Iterator[MapResult]:
    # TODO: validate?
    transform = self._find_transform(service, resource_name)
    if transform.version != 1:
      raise GFInternal(
          f'v1 mapper called for {resource_name} with version {transform.version}'
      )
    parent_kwargs = {} if parent_args is None else parent_args
    for spec in transform.resources:
      yield from self._map_spec_v1(transform.service, spec, raw_list, ctx,
                                   resource_name, raw_uri_fn, parent_kwargs)
    for subspec in transform.subresources:
      for parent in raw_list:
        subresources = parent.get(subspec.key, [])
        parent_params = {
            k: self.value_from_spec(v, parent, parent=parent_args)
            for k, v in subspec.parent.items()
        }
        yield from self._map_resources_v1(subresources,
                                          ctx,
                                          service,
                                          subspec.typ,
                                          partial(raw_uri_fn,
                                                  resource_name=subspec.typ),
                                          parent_args=parent_params)

  def _map_partial_v1(self, partial_spec: PartialSpec, raw_list: List[Any],
                      ctx: Context, service: str, raw_uri_fn: Callable,
                      resource_name: str) -> Iterator[Partial]:
    provider_attr_spec = partial_spec.attributes.get('provider', [])
    uri_fn = partial(raw_uri_fn, resource_name=resource_name)
    for raw in raw_list:
      uri_args = {
          key: _find_path(path, raw)
          for key, path in partial_spec.uri.items()
      }
      target_uri = uri_fn(**uri_args, service=service, context=ctx)
      if target_uri is None:
        raise GFInternal(
            f'Failed to produce target uri {uri_args} {resource_name} {service} {ctx}'
        )
      provider_attrs = self._map_provider_attrs(provider_attr_spec, raw)
      yield Partial(target_uri=target_uri, raw=raw, attrs=provider_attrs)

  def _map_partials_v1(self, transform: Transform, raw_list: List[Any],
                       ctx: Context, service: str, raw_uri_fn: Callable,
                       resource_name: str) -> Iterator[Partial]:
    for partial in transform.partials:
      yield from self._map_partial_v1(partial, raw_list, ctx, service,
                                      raw_uri_fn, resource_name)

  def map_partials(self, raw_list: List[Any], ctx: Context, service: str,
                   raw_uri_fn: Callable,
                   resource_name: str) -> Iterator[Partial]:
    transform = self._find_transform(service, resource_name)
    if transform.version >= 1:
      yield from self._map_partials_v1(transform, raw_list, ctx, service,
                                       raw_uri_fn, resource_name)

  def map_resources(self,
                    raw_list: List[Any],
                    ctx: Optional[Context],
                    service: str,
                    resource_name: str,
                    raw_uri_fn: Callable,
                    parent_args: Optional[Dict] = None) -> Iterator[MapResult]:
    transform = self._find_transform(service, resource_name)
    if transform.version >= 1:
      yield from self._map_resources_v1(raw_list, ctx or {}, service,
                                        resource_name, raw_uri_fn, parent_args)

  def _map_spec_relations_v1(
      self, spec, uri_fn: UriFn, uri_args, raw: Any, ctx: Context,
      parent_kwargs: Dict) -> Iterator[Tuple[Uri, str, Uri, List[Any]]]:
    relation_specs = spec.get('relations', [])
    service = spec['service']
    try:
      source_uri = uri_fn(**uri_args,
                          **parent_kwargs,
                          service=spec['service'],
                          context=ctx)
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
                                    uri_fn, raw, parent_kwargs, service, ctx)

  def _map_in_relation(
      self, path: str, category: str,
      resource_uri: Uri) -> Iterator[Tuple[Uri, str, str, List[Any]]]:
    if category == 'Organization':
      # Orgs are not in anything
      return
    elif category == 'Division':
      division_uri = self._division_uri.uri_for_parent(path)
    else:
      division_uri = self._division_uri.uri_for_path(path)
    yield resource_uri, 'in', division_uri, []

  def _map_relation_spec_v1(
      self, spec, path: str, raw_list, ctx: Dict, resource_name: str,
      raw_uri_fn, parent_args: Optional[Dict]
  ) -> Iterator[Tuple[Uri, str, Uri, List[Any]]]:
    resource_name = spec.get('resource_name', resource_name)
    parent_kwargs = {} if parent_args is None else parent_args
    for raw in raw_list:
      uri_args = self._uri_args(spec, raw)
      uri_args['path'] = path
      uri_args['resource_name'] = resource_name
      yield from self._map_spec_relations_v1(spec, raw_uri_fn, uri_args, raw,
                                             ctx, parent_kwargs)

  def _map_relations_v1(
      self,
      path: str,
      raw_list,
      ctx: Context,
      service: str,
      resource_name: str,
      raw_uri_fn: UriFn,
      parent_args: Optional[Dict] = None
  ) -> Iterator[Tuple[Uri, str, Uri, List[Any]]]:
    # TODO: validate?
    transform = self._find_transform(service, resource_name)
    version = transform.spec.get('version', 0)
    if version != 1:
      raise GFInternal(
          f'v1 mapper called for {resource_name} with version {version}')
    resource_specs = transform.spec.get('resources', [])
    for spec in resource_specs:
      yield from self._map_relation_spec_v1(spec, path, raw_list, ctx,
                                            resource_name, raw_uri_fn,
                                            parent_args)
    subspecs = transform.spec.get('subresources', [])
    for spec in subspecs:
      subresource_key = spec.get('key')
      subresource_name = spec.get('type')
      parent_params_spec = spec.get('parent', {})
      for parent in raw_list:
        subresources = parent.get(subresource_key, [])
        parent_params = {
            k: self.value_from_spec(v, parent, parent=parent_args)
            for k, v in parent_params_spec.items()
        }
        yield from self.map_relations(path,
                                      subresources,
                                      ctx,
                                      service,
                                      subresource_name,
                                      partial(raw_uri_fn,
                                              resource_name=subresource_name),
                                      parent_args=parent_params)

  def map_relations(
      self,
      path: str,
      raw_list,
      ctx: Context,
      service: str,
      resource_name: str,
      raw_uri_fn: UriFn,
      parent_args: Optional[Dict] = None
  ) -> Iterator[Tuple[Uri, str, Uri, List[Any]]]:
    # TODO: ctx for uris?
    # TODO: document hierarchy of args for uri fns
    transform = self._find_transform(service, resource_name)
    version = transform.spec.get('version', 0)
    if version >= 1:
      yield from self._map_relations_v1(path, raw_list, ctx, service,
                                        resource_name, raw_uri_fn, parent_args)

  def _map_relation(self, relation_spec, parent_uri, uri_args, uri_fn, raw,
                    parent_args, service: str, ctx):
    # TODO: This feature is a hack / escape hatch for hard-to-model relations
    fn_name = relation_spec.get('fn')
    fn = None
    if fn_name is not None:
      fn = self.fn(fn_name)
    invert = relation_spec.get('invert', False)
    relation = relation_spec.get('relation')
    path = relation_spec['path']
    if path == '':
      targets = [raw]
    elif isinstance(path, dict):
      target = {
          key: jmespath.search(value, raw)
          for key, value in path.items()
      }
      targets = [target]
    else:
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
      target_args = {'parent_uri': uri_args.copy(), 'service': service}
      for key, spec in relation_spec['uri'].items():
        value = self.value_from_spec(spec, target, parent=raw)
        target_args[key] = value
      try:
        target_uri = uri_fn(**target_args, **parent_args, context=ctx)
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
