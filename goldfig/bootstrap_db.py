from dataclasses import dataclass
from goldfig.error import GFError
import logging
import os
from typing import Iterator, List, Tuple

# import psycopg2.errors
import psycopg2
from psycopg2 import sql
from sqlalchemy import create_engine, text
from sqlalchemy.pool import NullPool
from sqlalchemy.exc import OperationalError
from sqlalchemy.orm import sessionmaker, Session

from goldfig import models

_log = logging.getLogger(__name__)

DBNAME = 'goldfig'
HOST = os.environ.get('GOLDFIG_DB_HOST', 'localhost')
PORT = int(os.environ.get('GOLDFIG_DB_PORT', 5432))


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
                                 host=f'{HOST}:5432')

_ReadonlyCredential = DbCredential(db_name=DBNAME,
                                   user='goldfig_ro',
                                   password='goldfig_ro',
                                   host=f'{HOST}:5432')

_import_engine = None
_readonly_engine = None

SCHEMA_VERSION = 1


def _require_plv8(cursor):
  cursor.execute('''
    SELECT
      installed_version IS NOT NULL AS installed
    FROM
      pg_available_extensions WHERE
      name ='plv8'
    ''')
  is_installed = cursor.fetchone()[0]
  if is_installed is None:
    raise GFError('plv8 postgresql extension required but not available')
  elif not is_installed:
    # It's available, but not installed
    cursor.execute('CREATE EXTENSION plv8')


def _fn_files() -> Tuple[str, List[str]]:
  path = os.path.realpath(os.path.join(os.path.dirname(__file__), 'fns'))
  files = [
      f for f in os.listdir(path)
      if os.path.isfile(os.path.join(path, f)) and f[-4:] == '.sql'
  ]
  files.sort()
  return path, files


def _install_functions(db: Session):
  path, files = _fn_files()
  for fname in files:
    with open(os.path.join(path, fname), 'r') as f:
      sql = f.read()
      try:
        stmt = text(sql)
        db.execute(stmt)
      except:
        _log.error(f'failed adding function from {fname}')
        raise


def _view_files() -> Tuple[str, List[str]]:
  path = os.path.realpath(os.path.join(os.path.dirname(__file__), 'views'))
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
  result = db.execute('''
    SELECT
      matviewname AS view_name
    FROM
      pg_matviews
    WHERE
      schemaname = 'public'
  ''')
  for row in result:
    view = row['view_name']
    db.execute('REFRESH MATERIALIZED VIEW ' + view)


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


def _install_schema(db: Session) -> None:
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
    db.execute(
        'CREATE INDEX case_insensitive_name_idx ON resource_attribute (type, lower(attr_name))'
    )
    version = models.SchemaVersion(version=SCHEMA_VERSION)
    db.add(version)
    db.commit()
  elif version.version != SCHEMA_VERSION:
    raise NotImplementedError('Need schema migration')
  install_views(db)
  _install_functions(db)
  db.commit()


def _install_db_and_roles():
  print('creating goldfig database and installing roles')
  cred = DbCredential(db_name='postgres',
                      host=HOST,
                      user=os.environ.get('GOLDFIG_DB_SU_USER', 'postgres'),
                      password=os.environ.get('GOLDFIG_DB_SU_PASSWORD',
                                              'postgres'))
  su_conn = psycopg2.connect(dbname=cred.db_name,
                             user=cred.user,
                             password=cred.password,
                             host=cred.host)
  su_conn.autocommit = True
  cursor = su_conn.cursor()
  cursor.execute('CREATE DATABASE goldfig')
  cursor.close()
  su_conn.autocommit = False
  cursor = su_conn.cursor()
  for user in (_ImportCredential, _ReadonlyCredential):
    cursor.execute(
        sql.SQL('CREATE USER {} WITH ENCRYPTED PASSWORD %s').format(
            sql.Identifier(user.user)), (user.password, ))

  su_conn.commit()
  su_conn.close()

  cred = DbCredential(db_name='goldfig',
                      host=cred.host,
                      user=cred.user,
                      password=cred.password)
  su_conn = psycopg2.connect(dbname=cred.db_name,
                             user=cred.user,
                             password=cred.password,
                             host=cred.host)
  su_conn.autocommit = False
  cursor = su_conn.cursor()
  _require_plv8(cursor)
  import_user = sql.Identifier(_ImportCredential.user)
  ro_user = sql.Identifier(_ReadonlyCredential.user)
  cursor.execute('revoke create on schema public from public')
  cursor.execute(
      sql.SQL('grant all privileges on schema public to {}').format(
          import_user))
  cursor.execute(
      sql.SQL('grant select on all tables in schema public to {}').format(
          ro_user))
  cursor.execute(
      sql.SQL(
          'alter default privileges for role {} in schema public grant select on tables to {}'
      ).format(import_user, ro_user))
  cursor.close()
  su_conn.commit()


# TODO: switch to something like alembic?
def init_db():
  try:
    db = import_session()
  except OperationalError as e:
    if 'password authentication failed' in str(
        e) or 'database "goldfig" does not exist' in str(e):
      # need to set up db
      _install_db_and_roles()
      db = import_session()
    else:
      raise
  _install_schema(db)


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
  from goldfig import models
  models.Base.metadata.create_all(engine)
  return sessionmaker(bind=engine)()
