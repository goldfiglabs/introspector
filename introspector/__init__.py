import concurrent.futures as f
import logging
import os
import traceback
from typing import Any, Dict, List, Optional, Union

from sqlalchemy.orm import Session

from introspector.models import ImportJob, RawImport

GOLDFIG_ROOT = os.path.abspath(os.path.dirname(__file__))

_log = logging.getLogger(__name__)


# TODO: this is probably not great
class PathStack(object):
  @classmethod
  def from_import_job(cls, import_job: ImportJob) -> 'PathStack':
    return cls([import_job.path_prefix])

  def __init__(self, tokens: List[str]):
    self._tokens = tokens

  def scope(self, token: str) -> 'PathStack':
    new_tokens = self._tokens.copy()
    new_tokens.append(token)
    return PathStack(new_tokens)

  def path(self) -> str:
    return '$'.join(self._tokens)

  def tail(self) -> str:
    return self._tokens[-1]


GLOBAL = '$'


class ImportWriter:
  def __init__(self, db: Session, import_job_id: int, provider_account_id: int,
               service: str, phase: int, source: str):
    self._db = db
    self._import_job_id = import_job_id
    self._provider_account_id = provider_account_id
    self._phase = phase
    self._service = service
    self.source = source

  def for_source(self, source: str) -> 'ImportWriter':
    return ImportWriter(self._db, self._import_job_id,
                        self._provider_account_id, self._service, self._phase,
                        source)

  def __call__(self,
               path: Union[PathStack, str],
               resource_name: str,
               raw: Any,
               context: Optional[Dict] = None):
    if isinstance(path, PathStack):
      path = path.path()
    _log.debug(f'writing {self.source} - {path} - {resource_name}')
    model = RawImport(import_job_id=self._import_job_id,
                      provider_account_id=self._provider_account_id,
                      path=path,
                      service=self._service,
                      resource_name=resource_name,
                      raw=raw,
                      context=context,
                      phase=self._phase,
                      source=self.source)
    self._db.add(model)


def db_import_writer(db: Session, import_job_id: int, provider_account_id: int,
                     service: str, phase: int, source: str) -> ImportWriter:
  return ImportWriter(db, import_job_id, provider_account_id, service, phase,
                      source)


def collect_exceptions(results: List[f.Future]) -> List[str]:
  exceptions = []
  for result in results:
    try:
      _ = result.result()
    except:
      exc = traceback.format_exc()
      _log.error('exception caught in import', exc_info=True)
      exceptions.append(exc)
  return exceptions
