import concurrent.futures as f
import logging
import os
import traceback
from typing import Any, Callable, Dict, List, Optional, Union

from sqlalchemy.orm import Session

from goldfig.models import ImportJob, RawImport

GOLDFIG_ROOT = os.path.abspath(os.path.dirname(__file__))

_log = logging.getLogger(__name__)


# TODO: this is probably not great
class PathStack(object):
  @classmethod
  def from_import_job(cls, import_job: ImportJob) -> 'PathStack':
    return cls([])

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
  def __init__(self, db: Session, import_job_id: int, service: str,
               phase: int):
    self._db = db
    self._import_job_id = import_job_id
    self._phase = phase
    self._service = service

  def __call__(self,
               path: Union[PathStack, str],
               resource_name: str,
               raw: Any,
               context: Optional[Dict] = None):
    if isinstance(path, PathStack):
      path = path.path()
    _log.info(f'writing {path} - {resource_name}')
    model = RawImport(import_job_id=self._import_job_id,
                      path=path,
                      service=self._service,
                      resource_name=resource_name,
                      raw=raw,
                      context=context,
                      phase=self._phase)
    self._db.add(model)


def db_import_writer(db: Session, import_job_id: int, service: str,
                     phase: int) -> ImportWriter:
  return ImportWriter(db, import_job_id, service, phase)


def collect_exceptions(results: List[f.Future]) -> List[str]:
  exceptions = []
  for result in results:
    try:
      _ = result.result()
    except:
      exceptions.append(traceback.format_exc())
  return exceptions
