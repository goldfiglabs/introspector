from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

from sqlalchemy import (Column, Integer, String, ForeignKey, DateTime)
from sqlalchemy.orm import relationship, Session
from sqlalchemy.dialects.postgresql import JSONB


@dataclass
class AwsAccount:
  id: str


AwsAccounts = Dict[str, List[AwsAccount]]


@dataclass
class AwsGraph:
  accounts: AwsAccounts


@dataclass
class AwsConfig:
  graph: AwsGraph


def _utc_now() -> datetime:
  return datetime.now(timezone.utc)


from introspector.models.base import Base
from introspector.models.provider_account import ProviderAccount


class ImportJob(Base):
  __tablename__ = 'import_job'
  __table_args__ = {
      'comment':
      '(Internal) Keeps track of pending import jobs and associated metadata.'
  }
  id = Column(Integer, primary_key=True, comment='Row id.')
  start_date = Column(DateTime,
                      default=_utc_now,
                      nullable=False,
                      comment='Import start date and time.')
  end_date = Column(DateTime,
                    default=None,
                    nullable=True,
                    comment='Import end date and time.')
  error_details = Column(JSONB,
                         default=None,
                         comment='Upon import failure error details.')
  path_prefix = Column(String(256),
                       nullable=False,
                       comment='Import path prefix.')
  configuration = Column(
      JSONB, comment='Import configuration for which provider and account id.')
  provider_account_id = Column(Integer,
                               ForeignKey('provider_account.id'),
                               nullable=False,
                               comment='Import job provider account id.')

  provider = relationship('ProviderAccount')

  _aws_config: Optional[AwsConfig] = None

  @classmethod
  def create(cls, provider: ProviderAccount, config, account: str) -> 'ImportJob':
    return cls(provider=provider, configuration=config, path_prefix=account)

  @classmethod
  def latest(cls, db: Session,
             provider_account_id: int) -> Optional['ImportJob']:
    return db.query(cls).filter(
        cls.provider_account_id == provider_account_id,
        cls.end_date != None).order_by(
            cls.start_date.desc()).limit(1).one_or_none()

  def mark_complete(self, exceptions: List[str]):
    self.end_date = _utc_now()
    if len(exceptions) != 0:
      self.error_details = exceptions

  def __repr__(self):
    return f'<ImportJob(id={self.id}, provider_account_id={self.provider_account_id})>'

  @property
  def aws_config(self) -> AwsConfig:
    if self._aws_config is None:
      config: Any = self.configuration
      graph: Any = config['aws_graph']
      accounts: AwsAccounts = {
          path: [AwsAccount(id=account['Id']) for account in accounts]
          for path, accounts in graph['accounts'].items()
      }
      self._aws_config = AwsConfig(graph=AwsGraph(accounts=accounts))
    return self._aws_config