import os
import yaml

import goldfig.gcp as gcp
from goldfig.gcp.map import GCP_MAPPER_FNS
from goldfig.mapper import DivisionURI, Mapper, Transform, Transforms

_disk_raw = {
    "id": "7384694770064152004",
    "kind": "compute#disk",
    "name": "disk-unattached",
    "type":
    "https://www.googleapis.com/compute/beta/projects/goldfiglabs/zones/us-central1-a/diskTypes/pd-standard",
    "zone":
    "https://www.googleapis.com/compute/beta/projects/goldfiglabs/zones/us-central1-a",
    "labels": {
        "type": "unattached",
        "owner": "vikrum"
    },
    "sizeGb": "10",
    "status": "READY",
    "selfLink":
    "https://www.googleapis.com/compute/beta/projects/goldfiglabs/zones/us-central1-a/disks/disk-unattached",
    "description": "Unattached disk created by `vikrum`",
    "labelFingerprint": "p4DKEJf-neo=",
    "creationTimestamp": "2020-06-26T14:39:55.198-07:00",
    "physicalBlockSizeBytes": "4096"
}


def _dummy_uri(uri: str, **kwargs) -> str:
  return uri


def _provider_attrs(attrs):
  return list(filter(lambda attr: attr['type'] == 'provider', attrs))


def _attr(attrs, typ: str, name: str):
  for attr in attrs:
    if attr['type'] == typ and attr['name'] == name:
      return attr['value']
  raise ValueError(f'Attribute {typ} {name} not found')


def test_gcp_disk_mapper_v1():
  disk_transform_path = os.path.join(os.path.dirname(gcp.__file__),
                                     'transforms', 'compute', 'disks.yml')
  with open(disk_transform_path, 'r') as f:
    v1_transform = yaml.safe_load(f)
  transforms: Transforms = {'svc': {'disk': Transform('svc', v1_transform)}}
  division_uri = DivisionURI()
  mapper = Mapper(transforms,
                  provider_account_id=0,
                  division_uri=division_uri,
                  extra_fns=GCP_MAPPER_FNS)
  mapped = list(
      mapper.map_resources(raw_list=[_disk_raw],
                           ctx=None,
                           service='svc',
                           resource_name='disk',
                           raw_uri_fn=_dummy_uri))
  assert len(mapped) == 1
  resource, attrs = mapped[0]
  assert resource[
      'uri'] == 'https://www.googleapis.com/compute/beta/projects/goldfiglabs/zones/us-central1-a/disks/disk-unattached'
  assert {
      'type': 'Metadata',
      'name': 'Tags',
      'value': {
          "type": "unattached",
          "owner": "vikrum"
      }
  } in attrs
  assert resource['uri'] == _disk_raw['selfLink']
  provider_attrs = _provider_attrs(attrs)
  assert len(provider_attrs) == len(_disk_raw)
  labels = _attr(attrs, 'Metadata', 'Tags')
  assert len(labels) == 2
  zone = _attr(attrs, 'Metadata', 'Zone')
  assert zone == 'us-central1-a'


def test_context():
  transforms: Transforms = {
      'svc': {
          'foo':
          Transform(
              'svc', {
                  'version':
                  1,
                  'resources': [{
                      'name': 'name',
                      'provider_type': 'foo',
                      'uri': {
                          'name': 'name'
                      },
                      'service': 'foo_svc',
                      'attributes': {
                          'custom': {
                              'Metadata': {
                                  'FromContext': {
                                      'context': 'bar'
                                  }
                              }
                          }
                      }
                  }]
              })
      }
  }
  division_uri = DivisionURI()
  mapper = Mapper(transforms, provider_account_id=0, division_uri=division_uri)
  raw_list = [{'name': 'FooName'}]
  ctx = {'bar': 'baz'}

  def uri_fn(name, context, **kwargs):
    return f'{name}-{context["bar"]}'

  results = list(
      mapper.map_resources(raw_list,
                           ctx,
                           service='svc',
                           resource_name='foo',
                           raw_uri_fn=uri_fn))
  assert len(results) == 1
  mapped, attrs = results[0]
  assert mapped['uri'] == 'FooName-baz'
  assert mapped['name'] == 'FooName'
  assert len(attrs) == 1
  attr = attrs[0]
  assert attr['type'] == 'Metadata'
  assert attr['name'] == 'FromContext'
  assert attr['value'] == 'baz'