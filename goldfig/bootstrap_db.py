from dataclasses import dataclass
import logging
import os
import re
import subprocess
from typing import Callable, List, Tuple

from sqlalchemy import create_engine, text
from sqlalchemy.pool import NullPool
from sqlalchemy.orm import sessionmaker, Session

_log = logging.getLogger(__name__)

DBNAME = 'goldfig'
HOST = os.environ.get('GOLDFIG_DB_HOST', 'localhost')
PORT = int(os.environ.get('GOLDFIG_DB_PORT', 5432))
SSLMODE = os.environ.get('GOLDFIG_PG_SSLMODE', 'disable')


@dataclass
class DbCredential:
  db_name: str
  user: str
  password: str
  host: str
  port: int

  def connection_string(self) -> str:
    return f'postgresql+psycopg2://{self.user}:{self.password}@{self.host}:{self.port}/{self.db_name}'

  def db_url(self) -> str:
    return f'postgresql://{self.user}:{self.password}@{self.host}:{self.port}/{self.db_name}?sslmode={SSLMODE}'


_ImportCredential = DbCredential(db_name=DBNAME,
                                 user='goldfig',
                                 password='goldfig',
                                 host=HOST,
                                 port=5432)

_ReadonlyCredential = DbCredential(db_name=DBNAME,
                                   user='goldfig_ro',
                                   password='goldfig_ro',
                                   host=HOST,
                                   port=5432)

_ReadonlyScopedCredential = DbCredential(db_name=DBNAME,
                                         user='goldfig_ro_scoped',
                                         password='goldfig_ro_scoped',
                                         host=HOST,
                                         port=5432)

_import_engine = None
_readonly_engine = None


def _view_files() -> Tuple[str, List[str]]:
  path = os.path.realpath(os.path.join(os.path.dirname(__file__), 'views'))
  files = [
      f for f in os.listdir(path)
      if os.path.isfile(os.path.join(path, f)) and f[-4:] == '.sql'
  ]
  files.sort()
  return path, files


_find_resource_alias = re.compile('resource AS ([_a-zA-Z0-9]+)', re.M | re.S)
_find_where = re.compile('^.*(WHERE).*$', re.M | re.S)


def _process_query(query_text: str, provider_account_id: int) -> str:
  # HACK: should really parse the query and edit it instead
  m = _find_resource_alias.search(query_text)
  alias = m[1]
  m = _find_where.match(query_text)
  _, where_end = m.span(1)
  to_insert = f'\n  {alias}.provider_account_id = {provider_account_id} AND '
  return query_text[:where_end] + to_insert + query_text[where_end:]


def _process_queries(query_text: str, provider_account_id: int):
  queries = [q.strip() for q in query_text.split(';') if q.strip() != '']
  processed = [_process_query(q, provider_account_id) for q in queries]
  return processed


def provider_tables(db: Session, provider_type: str) -> List[str]:
  provider_prefix = f'{provider_type}_%'
  result = db.execute(
      '''
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = 'public'
    AND table_name LIKE :provider_prefix
  ''', {'provider_prefix': provider_prefix})
  return [row[0] for row in result.fetchall()]


def refresh_views(db: Session, provider_account_id: int):
  path = os.path.realpath(os.path.join(os.path.dirname(__file__), 'queries'))
  files = [
      f for f in os.listdir(path)
      if os.path.isfile(os.path.join(path, f)) and f[-4:] == '.sql'
  ]
  files.sort()
  for filename in files:
    with open(os.path.join(path, filename), 'r') as f:
      query_txt = f.read()
    to_run = _process_queries(query_txt, provider_account_id)
    for query in to_run:
      result = db.execute(query)


def install_views(db: Session):
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


def _run_migration(cred: DbCredential, folder: str):
  cwd = os.getcwd()
  migrations_root = os.path.join(cwd, 'migrations')
  db_mate = os.path.join(cwd, 'dbmate')
  subprocess.run([
      db_mate, '--no-dump-schema', '--url',
      cred.db_url(), '--migrations-dir',
      os.path.join(migrations_root, folder), 'up'
  ]).check_returncode()


def _install_db_and_roles():
  su_cred = DbCredential(db_name='goldfig',
                         host=HOST,
                         user=os.environ.get('GOLDFIG_DB_SU_USER', 'postgres'),
                         password=os.environ.get('GOLDFIG_DB_SU_PASSWORD',
                                                 'postgres'),
                         port=5432)
  _run_migration(su_cred, 'superuser')
  _run_migration(_ImportCredential, 'goldfig')
  _run_migration(_ImportCredential, 'provider/aws')


def init_db():
  _install_db_and_roles()


def import_session() -> Session:
  global _import_engine
  if _import_engine is None:
    _import_engine = create_engine(_ImportCredential.connection_string(),
                                   connect_args={'connect_timeout': 3},
                                   poolclass=NullPool)
    # Force connection errors early
    _import_engine.connect()
  return sessionmaker(bind=_import_engine)()


def readonly_session() -> Session:
  global _readonly_engine
  if _readonly_engine is None:
    _readonly_engine = create_engine(_ReadonlyCredential.connection_string())
  return sessionmaker(bind=_readonly_engine)()


def db_from_connection(conn) -> Session:
  engine = create_engine('postgresql+psycopg2://', creator=lambda: conn)
  return sessionmaker(bind=engine)()


def scoped_readonly_session(provider_account_id: int) -> Session:
  engine = create_engine(_ReadonlyScopedCredential.connection_string())
  db = sessionmaker(bind=engine)()
  db.execute('SET gf.provider_account_id = :provider_account_id',
             {'provider_account_id': provider_account_id})
  return db


@dataclass
class ReadOnlyProviderDB:
  db: Session
  provider_account_id: int


def scope_readonly_session(fn: Callable[[Session], int]) -> ReadOnlyProviderDB:
  engine = create_engine(_ReadonlyScopedCredential.connection_string())
  db = sessionmaker(bind=engine)()
  provider_account_id = fn(db)
  db.execute('SET gf.provider_account_id = :provider_account_id',
             {'provider_account_id': provider_account_id})
  return ReadOnlyProviderDB(db=db, provider_account_id=provider_account_id)