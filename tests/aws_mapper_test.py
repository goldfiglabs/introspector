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
