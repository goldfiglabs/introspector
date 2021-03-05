import json

from introspector.aws.logs import normalize_resource_policies
from introspector.aws.map import AWS_TRANSFORMS

def test_account_principal():
  policy = {
    'Version': '2012-10-17',
    'Statement': [
      {
        'sid': "TestSid",
        'Effect': 'Allow',
        'principal': {
          "AWS": ["0123456789", "arn:aws:iam::987654321:user/greg"],
          'CanonicalUser': "abcdef0123456789",
          "Federated": "arn:aws:iam::1234512345:saml-provider/fooIdp"
        },
        'action': "S3:*",
        "resource": "*"
      }
    ]
  }
  normalized = AWS_TRANSFORMS['aws_policy'](policy)
  from pprint import pprint
  pprint(normalized)
  assert normalized['Statement'][0]['Principal']['AWS'][0] == 'arn:aws:iam::0123456789:root'

def test_logs_resource_policies():
  fixture = [
    {
      'policyName': 'policy1',
      'policyDocument': json.dumps({
        'Version': 'dummy',
        'Statement': [
          {
            'Resource': [
              'a:b/*',
              'c'
            ],
            'Effect': 'Allow'
          }
        ]
      })
    }
  ]
  from pprint import pprint
  result = normalize_resource_policies(fixture)
  pprint(result)
  assert False