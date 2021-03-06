from typing import List, Optional

from sqlalchemy import Column, ForeignKey, Integer, String, Enum
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm.session import Session

from introspector.models.base import Base


class ProviderAccount(Base):
  __tablename__ = 'provider_account'
  __table_args__ = {'comment': '(Internal) Provider account.'}
  id = Column(Integer, primary_key=True, comment='Row id.')
  name = Column(String(256), comment='Provider name.')
  provider = Column(Enum('aws', 'gcp', 'azure', name='provider'),
                    comment='Provider enum.')
  external_id = Column(
      Integer,
      comment='Optional external id for joining against external data sources')

  @classmethod
  def all(cls,
          db: Session,
          provider: Optional[str] = None) -> List['ProviderAccount']:
    query = db.query(cls)
    if provider is not None:
      query = query.filter(cls.provider == provider)
    return query.all()

  def __repr__(self) -> str:
    return f'<ProviderAccount id={self.id} provider={self.provider} account={self.name}>'


class ProviderCredential(Base):
  __tablename__ = 'provider_credential'
  __table_args__ = {'comment': '(Internal) Provider account credentials.'}
  id = Column(Integer, primary_key=True, comment='Row id.')
  provider_id = Column('provider_account_id',
                       Integer,
                       ForeignKey('provider_account.id'),
                       nullable=False,
                       comment='Provider id.')
  principal_uri = Column(String(1024),
                         nullable=False,
                         comment='Provider principal uri.')
  config = Column(JSONB, comment='Provider configuration.')
  scope = Column(String(128), comment='Provider scope.')

  @classmethod
  def for_provider(cls, db: Session,
                   provider_account_id: int) -> List['ProviderCredential']:
    return db.query(ProviderCredential).join(
        ProviderAccount,
        ProviderCredential.provider_id == ProviderAccount.id,
        aliased=True).filter(ProviderAccount.id == provider_account_id).all()
