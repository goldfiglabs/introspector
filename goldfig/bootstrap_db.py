from dataclasses import dataclass
import logging
import os
from typing import List, Tuple

# import psycopg2.errors
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker, Session

from goldfig import models

_log = logging.getLogger(__name__)

DBNAME = 'goldfig'
HOST = 'localhost'


@dataclass
class DbCredential:
  db_name: str
  user: str
  password: str
  host: str

  def connection_string(self) -> str:
    return f'postgresql+psycopg2://{self.user}:{self.password}@{self.host}/{self.db_name}'


_ImportCredential = DbCredential(db_name=DBNAME,
                                 user='goldfig',
                                 password='goldfig',
                                 host=HOST)

_ReadonlyCredential = DbCredential(db_name=DBNAME,
                                   user='goldfig_ro',
                                   password='goldfig_ro',
                                   host=HOST)

_import_engine = None
_readonly_engine = None

SCHEMA_VERSION = 1


def _view_files() -> Tuple[str, List[str]]:
  path = os.path.realpath(
      os.path.join(os.path.dirname(__file__), '..', 'views'))
  files = [
      f for f in os.listdir(path)
      if os.path.isfile(os.path.join(path, f)) and f[-4:] == '.sql'
  ]
  files.sort()
  return path, files


def view_names() -> List[str]:
  _, files = _view_files()
  return [fname[:-4] for fname in files]


def refresh_views(db: Session):
  for view in view_names():
    db.execute('REFRESH MATERIALIZED VIEW ' + view)


def _install_views(db: Session):
  path, files = _view_files()
  for fname in files:
    with open(os.path.join(path, fname), 'r') as f:
      sql = f.read()
      try:
        stmt = text(sql)
        db.execute(stmt)
      except:
        _log.error(f'failed adding view from {fname}')
        raise


# TODO: switch to something like alembic?
def init_db():
  db = import_session()
  version = None
  try:
    version = db.query(models.SchemaVersion).one_or_none()
  except:
    # TODO: catch a better error here
    # if the schema doesn't exist, the transaction will fail.
    # rollback so that subsequent operations open a new transaction.
    db.rollback()
  if version is None:
    # this is kinda bad, and should maybe be wrapped
    # in an admin credential, rather than the import one
    models.Base.metadata.create_all(_import_engine)
    version = models.SchemaVersion(version=SCHEMA_VERSION)
    db.add(version)
    db.commit()
  elif version.version != SCHEMA_VERSION:
    raise NotImplementedError('Need schema migration')
  _install_views(db)
  db.commit()


def import_session() -> Session:
  global _import_engine
  if _import_engine is None:
    _import_engine = create_engine(_ImportCredential.connection_string())
  return sessionmaker(bind=_import_engine)()


def readonly_session() -> Session:
  global _readonly_engine
  if _readonly_engine is None:
    _readonly_engine = create_engine(_ReadonlyCredential.connection_string())
  return sessionmaker(bind=_readonly_engine)()


def db_from_connection(conn) -> Session:
  engine = create_engine('postgresql+psycopg2://', creator=lambda: conn)
  from goldfig import models
  models.Base.metadata.create_all(engine)
  return sessionmaker(bind=engine)()
