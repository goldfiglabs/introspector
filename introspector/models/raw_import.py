import logging
from typing import Any, List

from sqlalchemy import Boolean, Column, Integer, ForeignKey, String
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import JSONB

from introspector.models.base import Base

_log = logging.getLogger(__name__)

ERROR_KEY = 'introspector'


class RawImport(Base):
  __tablename__ = 'raw_import'
  __table_args__ = {'comment': '(Internal) Raw import.'}
  id = Column(Integer, primary_key=True, comment='Row id.')
  import_job_id = Column(Integer,
                         ForeignKey('import_job.id'),
                         comment='Import job id.')
  provider_account_id = Column(Integer,
                               ForeignKey('provider_account.id'),
                               nullable=False,
                               comment='Import job provider account id.')
  source = Column(String(256),
                  nullable=False,
                  comment='Source of the data that produced this payload')
  service = Column(String(256), nullable=False)
  path = Column(String(1024), comment='Path for raw import.')
  resource_name = Column(String(256), comment='Resource name.')
  raw = Column(JSONB, comment='Raw JSON response from provider.')
  context = Column(
      JSONB,
      comment=
      'JSON dictionary of values relevant to the call(s) that produced this response'
  )
  phase = Column(Integer, nullable=False, comment='Phase of import job.')
  mapped = Column(Boolean,
                  nullable=False,
                  default=False,
                  comment='Has this import job been mapped?')

  # TODO: this is pretty ugly
  def raw_resources(self) -> List[Any]:
    if isinstance(self.raw, list):
      return self.raw
    else:
      try:
        return self.raw[self.resource_name]
      except KeyError:
        if len(self.raw.keys()) == 0:
          return []
        elif len(self.raw.keys()) == 1:
          key = list(self.raw.keys())[0]
          if key == ERROR_KEY:
            # This is an error condition that we saved in import
            return []
          _log.debug(f'Assuming key {key} for {self.resource_name}')
          return self.raw[key]
        else:
          # Whole thing is one resource
          return [self.raw]
      except TypeError as e:
        _log.error(f'Raw: {self.raw}', e)
        raise


class MappedURI(Base):
  __tablename__ = 'mapped_uri'
  __table_args__ = {'comment': '(Internal) Mapped URIs.'}
  uri = Column(String, nullable=False, primary_key=True, comment='Mapped URI.')
  source = Column(String(256), nullable=False, primary_key=True)
  import_job_id = Column(Integer,
                         ForeignKey('import_job.id'),
                         primary_key=True,
                         comment='Import job id.')
  provider_account_id = Column(Integer,
                               ForeignKey('provider_account.id'),
                               nullable=False,
                               comment='Import job provider account id.')
  raw_import_id = Column(Integer,
                         ForeignKey('raw_import.id'),
                         nullable=True,
                         comment='Raw import id.')
  raw_import = relationship('RawImport')
