from dataclasses import dataclass
from typing import Callable, Dict, List, Optional, Tuple, Union

from psycopg2 import sql
from psycopg2.extras import DictCursor
from sqlalchemy import Column, Enum, ForeignKey, func, Index, Integer, String, text, UniqueConstraint, CheckConstraint
from sqlalchemy.orm import relationship, Session
from sqlalchemy.dialects.postgresql import JSONB

from introspector.models.base import Base


@dataclass
class ResourceId:
  id: int
  uri: str


DbFn = Callable[[Session, int], List[ResourceId]]
LikeExpr = Tuple[str, str]
Uri = Union[str, LikeExpr, DbFn]
UriFn = Callable[..., Uri]


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
  provider_account_id = Column(Integer,
                               ForeignKey('provider_account.id'),
                               nullable=False)

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
  provider_account_id = Column(Integer,
                               ForeignKey('provider_account.id'),
                               nullable=False)

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
  provider_account_id = Column(Integer,
                               ForeignKey('provider_account.id'),
                               nullable=False)
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
  def get_by_uri(cls, session, uri: Uri,
                 provider_account_id: int) -> List[ResourceId]:
    if callable(uri):
      return uri(session, provider_account_id)
    else:
      q = session.query(Resource).filter(
          Resource.provider_account_id == provider_account_id)
      if isinstance(uri, str):
        q = q.filter(Resource.uri == uri)
      else:
        q = q.filter(Resource.uri.like(f'{uri[0]}%{uri[1]}'))
      r = q.one_or_none()
      if r is not None:
        return [ResourceId(id=r.id, uri=r.uri)]
      return []

  @classmethod
  def get_by_attrs(cls, session: Session, provider_account_id: int,
                   provider_type: str,
                   attrs: Dict[str, str]) -> Optional[ResourceId]:
    conn = session.connection()
    with conn.connection.cursor(cursor_factory=DictCursor) as cursor:
      joins = []
      values = {}
      for i, (k, v) in enumerate(attrs.items()):
        value = f'v_{i}'
        name = f'n_{i}'
        tbl = f't_{i}'
        values[value] = sql.Literal(v)
        values[name] = sql.Literal(k)
        values[tbl] = sql.Identifier(k)
        joins.append('''INNER JOIN resource_attribute AS {{{tbl}}}
              ON {{{tbl}}}.type = 'provider'
              AND {{{tbl}}}.attr_name = {{{name}}}
              AND {{{tbl}}}.attr_value #>> '{{{{}}}}' = {{{value}}}
              AND {{{tbl}}}.resource_id = R.id
          '''.format(tbl=tbl, name=name, value=value))
      txt = '\n'.join(joins)
      values['provider_type'] = sql.Literal(provider_type)
      values['provider_account_id'] = sql.Literal(provider_account_id)
      q = f'''
        SELECT
          R.id,
          R.uri
        FROM
          resource AS R
          {txt}
        WHERE
          R.provider_type = {{provider_type}}
          AND R.provider_account_id = {{provider_account_id}}
        '''
      query = sql.SQL(q).format(**values)
      cursor.execute(query)
      row = cursor.fetchone()
      if row is None:
        return None
      return ResourceId(id=row['id'], uri=row['uri'])


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
  provider_account_id = Column(Integer,
                               ForeignKey('provider_account.id'),
                               nullable=False)
  raw = Column(JSONB)


class ResourceAttribute(Base):
  __tablename__ = 'resource_attribute'
  __table_args__ = ({'comment': 'Attributes of resources.'})
  id = Column(Integer, primary_key=True)
  resource_id = Column(Integer, ForeignKey('resource.id'), nullable=False)
  provider_account_id = Column(Integer,
                               ForeignKey('provider_account.id'),
                               nullable=False)
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
  provider_account_id = Column(Integer,
                               ForeignKey('provider_account.id'),
                               nullable=False)
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
  provider_account_id = Column(Integer,
                               ForeignKey('provider_account.id'),
                               nullable=False)
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
  provider_account_id = Column(Integer,
                               ForeignKey('provider_account.id'),
                               nullable=False)
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
  provider_account_id = Column(Integer,
                               ForeignKey('provider_account.id'),
                               nullable=False)
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
