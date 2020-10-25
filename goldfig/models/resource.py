from sqlalchemy import Column, Enum, ForeignKey, func, Index, Integer, String, text, UniqueConstraint, CheckConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import JSONB

from goldfig.models.base import Base


class ResourceRelation(Base):
  __tablename__ = 'resource_relation'
  __table_args__ = (UniqueConstraint('resource_id',
                                     'relation',
                                     'target_id',
                                     name='relation_uc'), {
                                         'comment':
                                         'Relationships between resources.'
                                     })

  id = Column(Integer, primary_key=True)
  resource_id = Column(Integer, ForeignKey('resource.id'), nullable=False)
  relation = Column(String(50), nullable=False)
  target_id = Column(Integer, ForeignKey('resource.id'), nullable=False)
  raw = Column(JSONB)

  resource = relationship(
      'Resource', primaryjoin='ResourceRelation.resource_id==Resource.id')
  target = relationship('Resource',
                        primaryjoin='ResourceRelation.target_id==Resource.id')
  attributes = relationship('ResourceRelationAttribute', cascade='delete')

  def __repr__(self):
    return f'<ResourceRelation {self.resource_id} {self.relation} {self.target_id}>'


class ResourceRelationAttribute(Base):
  __tablename__ = 'resource_relation_attribute'
  __table_args__ = {
      'comment': 'Attributes on relationships between resources.'
  }

  id = Column(Integer, primary_key=True)
  relation_id = Column(Integer,
                       ForeignKey('resource_relation.id'),
                       nullable=False)
  name = Column(String(50))
  value = Column(JSONB)

  relation = relationship('ResourceRelation')


class Resource(Base):
  __tablename__ = 'resource'
  __table_args__ = (
      UniqueConstraint('provider_account_id', 'uri', name='provider_uri'),
      CheckConstraint('(NOT category IS NULL) OR (NOT provider_type IS NULL)',
                      name='type_exists'),
      Index('service_provider_type_idx', 'service', 'provider_type'), {
          'comment': 'Table of all imported resources across every provider.'
      })

  id = Column(Integer, primary_key=True)
  path = Column(String(1024), nullable=False)
  uri = Column(String(1024))
  name = Column(String(256))
  provider_account_id = Column(Integer, ForeignKey('provider_account.id'))
  provider_type = Column(String(1024), nullable=True)
  service = Column(String(256), nullable=True)
  '''
  ALTER TYPE category ADD VALUE 'new_value'; -- appends to list
  ALTER TYPE category ADD VALUE 'new_value' BEFORE 'old_value';
  ALTER TYPE category ADD VALUE 'new_value' AFTER 'old_value';
  '''
  category = Column(Enum('VMInstance',
                         'Disk',
                         'StorageBucket',
                         'Image',
                         'LoadBalancer',
                         'Certificate',
                         'Endpoint',
                         'Principal',
                         'Group',
                         'Policy',
                         'Role',
                         'Organization',
                         'Division',
                         name='resource_type'),
                    nullable=True)

  attributes = relationship('ResourceAttribute', cascade='delete')

  @classmethod
  def get_by_uri(cls, session, uri, provider_account_id):
    return session.query(Resource).filter(
        Resource.provider_account_id == provider_account_id,
        Resource.uri == uri).one_or_none()


class ResourceRaw(Base):
  __tablename__ = 'resource_raw'
  __table_args__ = (UniqueConstraint(
      'source', 'resource_id', name='payload_source'
  ), {
      'comment':
      'Holds the JSON representation of a resource from a particular source',
  })
  id = Column(Integer, primary_key=True)
  source = Column(String(256), nullable=False)
  resource_id = Column(Integer, ForeignKey('resource.id'), nullable=False)
  raw = Column(JSONB)


class ResourceAttribute(Base):
  __tablename__ = 'resource_attribute'
  __table_args__ = ({'comment': 'Attributes of resources.'})
  id = Column(Integer, primary_key=True)
  resource_id = Column(Integer, ForeignKey('resource.id'), nullable=False)
  source = Column(String(256), nullable=False)
  attr_type = Column('type', String(256))
  name = Column('attr_name', String(256))
  value = Column('attr_value', JSONB)

  resource = relationship('Resource')

  def __repr__(self) -> str:
    return f'<ResourceAttribute type={self.attr_type} name={self.name} value={self.value}>'


class ResourceDelta(Base):
  __tablename__ = 'resource_delta'
  __table_args__ = {
      'comment': 'Resource deltas between subseqnet import jobs.'
  }
  id = Column(Integer, primary_key=True)
  import_job_id = Column(Integer, ForeignKey('import_job.id'), nullable=False)
  # Foreign Key, but underlying resource might be deleted
  resource_id = Column(Integer, nullable=False)
  change_type = Column(Enum('add', 'update', 'delete', name='resource_change'))
  change_details = Column(JSONB)

  import_job = relationship('ImportJob')


class ResourceAttributeDelta(Base):
  __tablename__ = 'resource_attribute_delta'
  __table_args__ = {'comment': 'Deltas on attributes of resources'}
  id = Column(Integer, primary_key=True)
  resource_delta_id = Column(Integer, ForeignKey('resource_delta.id'))
  resource_attribute_id = Column(Integer, nullable=False)
  change_type = Column(Enum('add', 'update', 'delete',
                            name='attribute_change'))
  change_details = Column(JSONB)

  resource_delta = relationship('ResourceDelta')


class ResourceRelationDelta(Base):
  __tablename__ = 'resource_relation_delta'
  __table_args__ = {'comment': 'Deltas on relationships of resources.'}
  id = Column(Integer, primary_key=True)
  import_job_id = Column(Integer, ForeignKey('import_job.id'), nullable=False)
  # Foreign key, but underlying relation might be deleted
  resource_relation_id = Column(Integer, nullable=False)
  change_type = Column(Enum('add',
                            'update',
                            'delete',
                            name='resource_relation_change'),
                       nullable=False)
  change_details = Column(JSONB)

  import_job = relationship('ImportJob')


class ResourceRelationAttributeDelta(Base):
  __tablename__ = 'resource_relation_attribute_delta'
  __table_args__ = {
      'comment': 'Delta on attributes on relationships of resources.'
  }
  id = Column(Integer, primary_key=True)
  resource_relation_delta_id = Column(Integer,
                                      ForeignKey('resource_relation_delta.id'),
                                      nullable=False)
  # FK to resource_relation_attribute, but the attribute might be deleted
  resource_relation_attribute_id = Column(Integer, nullable=False)
  change_type = Column(Enum('add',
                            'update',
                            'delete',
                            name='relation_attribute_change'),
                       nullable=False)
  change_details = Column(JSONB)

  resource_relation_delta = relationship('ResourceRelationDelta')
