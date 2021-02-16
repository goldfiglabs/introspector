from introspector.mapper import DivisionURI, Mapper, Transform, Transforms


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
  assert mapped.uri == 'FooName-baz'
  assert mapped.name == 'FooName'
  assert len(attrs) == 1
  attr = attrs[0]
  assert attr.type == 'Metadata'
  assert attr.name == 'FromContext'
  assert attr.value == 'baz'