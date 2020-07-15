from datetime import datetime, timezone

from sqlalchemy import Column, DateTime, Integer

from goldfig.models.base import Base


def _utc_now() -> datetime:
  return datetime.now(timezone.utc)


class SchemaVersion(Base):
  __tablename__ = 'schema_version'
  __table_args__ = {
      'comment':
      '(Internal) Holds a single row with the current version of the goldfig schema'
  }
  id = Column(Integer, primary_key=True, comment='Row id.')
  version = Column(Integer,
                   comment='The current version of the goldfig schema')
  updated = Column(DateTime,
                   default=_utc_now,
                   nullable=False,
                   comment='When this version was installed')
