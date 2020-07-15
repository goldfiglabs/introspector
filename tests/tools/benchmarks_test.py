from sqlalchemy import text
from sqlalchemy.orm import Session

from goldfig.bootstrap_db import db_from_connection
from goldfig.models import ProviderAccount, Resource, ResourceAttribute, ResourceRelation
from goldfig.tools.cis import IamProfiles

import pytest
from pytest_postgresql import factories
pytest_plugins = ('pytest_postgresql', )


@pytest.fixture
def db(request, postgresql):
  db = db_from_connection(postgresql)
  yield db
  db.close()


_GCP_ID = 1
_AWS_ID = 2


# @pytest.fixture(scope='module')
def _iam_fixture(db: Session):
  # Providers
  gcp = ProviderAccount(id=_GCP_ID, name='test-gcp-account', provider='gcp')
  db.add(gcp)
  aws = ProviderAccount(id=_AWS_ID, name='test-aws-account', provider='aws')
  db.add(aws)
  db.flush()


def _multiple_tiers_service_account(db: Session):
  acct_id = 'abcd'
  org_id = 'abc'
  project_id = 'foo'
  prefix = lambda svc: '$'.join(
      ['gcp', acct_id, svc, f'organizations/{org_id}/project/{project_id}'])
  vm_path = '$'.join([prefix('compute'), 'zones/us-central1-a'])
  r1 = Resource(path=vm_path,
                uri='https://project/foo/instances/vm-1',
                name='vm-1',
                provider_account_id=_GCP_ID,
                category='VMInstance')
  db.add(r1)
  ra1 = ResourceAttribute(resource=r1,
                          attr_type='Metadata',
                          name='Tags',
                          value={
                              'role': 'web',
                              'metadata:foo': 'bar'
                          })
  db.add(ra1)
  r2 = Resource(path=vm_path,
                uri='https://project/foo/instances/vm-2',
                name='vm-2',
                provider_account_id=_GCP_ID,
                category='VMInstance')
  db.add(r2)
  ra2 = ResourceAttribute(resource=r2,
                          attr_type='Metadata',
                          name='Tags',
                          value={
                              'role': 'web',
                              'metadata:foo': 'baz'
                          })
  db.add(ra2)
  # App tier machine
  r3 = Resource(path=vm_path,
                uri='https://project/foo/instances/vm-3',
                name='vm-3',
                provider_account_id=_GCP_ID,
                category='VMInstance')
  db.add(r3)
  ra3 = ResourceAttribute(resource=r3,
                          attr_type='Metadata',
                          name='Tags',
                          value={
                              'role': 'app',
                              'metadata:xxx': 'yyy'
                          })
  db.add(ra3)

  # Shared service account
  iam_path = prefix('iam'),
  sa1 = Resource(
      path=iam_path,
      uri=
      f'organizations/{org_id}/projects{project_id}$serviceAccount:aaa@bbb.com',
      name='serviceAccount:aaa@bbb.com',
      provider_account_id=_GCP_ID,
      category='Policy')
  db.add(sa1)
  db.flush()

  # Relations
  rr1 = ResourceRelation(resource_id=r1.id,
                         relation='acts-as',
                         target_id=sa1.id)
  db.add(rr1)
  rr2 = ResourceRelation(resource_id=r2.id,
                         relation='acts-as',
                         target_id=sa1.id)
  db.add(rr2)
  rr3 = ResourceRelation(resource_id=r3.id,
                         relation='acts-as',
                         target_id=sa1.id)
  db.add(rr3)
  db.flush()


def _multiple_service_accounts(db: Session):
  # GCP
  #
  # scenario 1
  # 2 vms, both web, use different service accounts
  acct_id = 'abcd'
  org_id = 'abc'
  project_id = 'foo'
  prefix = lambda svc: '$'.join(
      ['gcp', acct_id, svc, f'organizations/{org_id}/project/{project_id}'])
  vm_path = '$'.join([prefix('compute'), 'zones/us-central1-a'])
  r1 = Resource(path=vm_path,
                uri='https://project/foo/instances/vm-1',
                name='vm-1',
                provider_account_id=_GCP_ID,
                category='VMInstance')
  db.add(r1)
  ra1 = ResourceAttribute(resource=r1,
                          attr_type='Metadata',
                          name='Tags',
                          value={
                              'role': 'web',
                              'metadata:foo': 'bar'
                          })
  db.add(ra1)
  r2 = Resource(path=vm_path,
                uri='https://project/foo/instances/vm-2',
                name='vm-2',
                provider_account_id=_GCP_ID,
                category='VMInstance')
  db.add(r2)
  ra2 = ResourceAttribute(resource=r2,
                          attr_type='Metadata',
                          name='Tags',
                          value={
                              'role': 'web',
                              'metadata:foo': 'baz'
                          })
  db.add(ra2)
  iam_path = prefix('iam'),
  sa1 = Resource(
      path=iam_path,
      uri=
      f'organizations/{org_id}/projects{project_id}$serviceAccount:aaa@bbb.com',
      name='serviceAccount:aaa@bbb.com',
      provider_account_id=_GCP_ID,
      category='Policy')
  db.add(sa1)
  sa2 = Resource(
      path=iam_path,
      uri=
      f'organizations/{org_id}/projects{project_id}$serviceAccount:ccc@bbb.com',
      name='serviceAccount:ccc@bbb.com',
      provider_account_id=_GCP_ID,
      category='Policy')
  db.add(sa2)
  db.flush()

  rr1 = ResourceRelation(resource_id=r1.id,
                         relation='acts-as',
                         target_id=sa1.id)
  db.add(rr1)
  rr2 = ResourceRelation(resource_id=r2.id,
                         relation='acts-as',
                         target_id=sa2.id)
  db.add(rr2)
  db.flush()


def test_providers(db):
  stmt = text('select count(*) from provider_account')
  result = db.execute(stmt).scalar()
  assert result == 0
  _iam_fixture(db)
  result = db.execute(stmt).scalar()
  assert result == 2


def test_shared_policy_with_other_tier_gcp(db):
  _iam_fixture(db)
  _multiple_tiers_service_account(db)
  profiles = IamProfiles()
  results = profiles.exec(db,
                          provider_account_id=_GCP_ID,
                          tier_tag=('role', 'web'))
  assert len(results['multiple_policies_violations']) == 0
  assert len(results['shared_policies_violations']) == 1


def test_tier_has_multiple_policies_gcp(db):
  _iam_fixture(db)
  _multiple_service_accounts(db)
  profiles = IamProfiles()
  results = profiles.exec(db,
                          provider_account_id=_GCP_ID,
                          tier_tag=('role', 'web'))
  multiple = results['multiple_policies_violations']
  # There are two policies in use, each policy is a key
  assert len(multiple.keys()) == 2