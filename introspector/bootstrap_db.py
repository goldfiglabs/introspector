from dataclasses import dataclass
import logging
import os
import subprocess
import time
from typing import Callable, List, Optional
import urllib.parse

import psycopg2
from sqlalchemy import create_engine
from sqlalchemy.engine.base import Engine
from sqlalchemy.pool import NullPool
from sqlalchemy.orm import sessionmaker, Session

_log = logging.getLogger(__name__)

DBNAME = os.environ.get('INTROSPECTOR_DB', 'introspector')
HOST = os.environ.get('INTROSPECTOR_DB_HOST', 'localhost')
PORT = int(os.environ.get('INTROSPECTOR_DB_PORT', 5432))
SSLMODE = os.environ.get('INTROSPECTOR_PG_SSLMODE', 'disable')
IS_RDS = os.environ.get('INTROSPECTOR_USE_RDS', 'disable') == 'enable'
if IS_RDS:
  import boto3
  import botocore.credentials
  import botocore.session


@dataclass
class DbCredential:
  db_name: str
  user: str
  password: str
  host: str
  port: int

  def _connection_string(self) -> str:
    password = urllib.parse.quote(self.password)
    return f'postgresql+psycopg2://{self.user}:{password}@{self.host}:{self.port}/{self.db_name}?sslmode={SSLMODE}'

  def db_url(self) -> str:
    return f'postgresql://{self.user}:{self.password}@{self.host}:{self.port}/{self.db_name}?sslmode={SSLMODE}'

  def _connection_factory(self, *args, **kwargs):
    assert IS_RDS
    # Prefer container provider over env, since env is likely
    # overridden with the target account
    boto_session = botocore.session.get_session()
    resolver = boto_session.get_component('credential_provider')
    container_provider = resolver.get_provider('container-role')
    resolver.remove('container-role')
    resolver.insert_before('env', container_provider)
    boto3_session = boto3.Session(botocore_session=boto_session)
    region = os.environ['AWS_REGION']
    host = os.environ.get('INTROSPECTOR_RDS_HOST', self.host)
    rds = boto3_session.client('rds', region_name=region)
    token = rds.generate_db_auth_token(DBHostname=host,
                                       Port=5432,
                                       DBUsername=self.user,
                                       Region=region)
    return psycopg2.connect(database=self.db_name,
                            user=self.user,
                            password=token,
                            host=self.host,
                            port=self.port,
                            sslmode='require')

  def create_engine(self) -> Engine:
    if IS_RDS:
      return create_engine('postgres+psycopg2://user:pass@host:5432/db',
                           connect_args={
                               "connection_factory": self._connection_factory,
                               'connect_timeout': 3
                           },
                           poolclass=NullPool)
    else:
      return create_engine(self._connection_string(),
                           connect_args={'connect_timeout': 3},
                           poolclass=NullPool)


_ImportCredential = DbCredential(
    db_name=DBNAME,
    user=os.environ.get('INTROSPECTOR_IMPORT_USER', 'introspector'),
    password=os.environ.get('INTROSPECTOR_IMPORT_PW', 'introspector'),
    host=HOST,
    port=PORT)

_ReadonlyCredential = DbCredential(
    db_name=DBNAME,
    user=os.environ.get('INTROSPECTOR_RO_USER', 'introspector_ro'),
    password=os.environ.get('INTROSPECTOR_RO_PW', 'introspector_ro'),
    host=HOST,
    port=PORT)

_ReadonlyScopedCredential = DbCredential(
    db_name=DBNAME,
    user=os.environ.get('INTROSPECTOR_SCOPED_USER', 'introspector_ro_scoped'),
    password=os.environ.get('INTROSPECTOR_SCOPED_PW',
                            'introspector_ro_scoped'),
    host=HOST,
    port=PORT)

_SuperUserCredential = DbCredential(
    db_name=DBNAME,
    host=HOST,
    user=os.environ.get('INTROSPECTOR_DB_SU_USER', 'postgres'),
    password=os.environ.get('INTROSPECTOR_DB_SU_PASSWORD', 'postgres'),
    port=PORT)

_import_engine: Optional[Engine] = None
_readonly_engine: Optional[Engine] = None


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
    # HACK. only use for query files we generated. not robust to strings containing ';'
    to_run = [q.strip() for q in query_txt.split(';') if q.strip() != '']
    start = time.time()
    for query in to_run:
      result = db.execute(query, {'provider_account_id': provider_account_id})
    end = time.time()
    _log.debug(filename, end - start)
    db.commit()


def _run_migration(cred: DbCredential,
                   folder: str,
                   label: str,
                   skip_if_empty: bool = False):
  cwd = os.getcwd()
  migrations_root = os.path.join(cwd, 'migrations')
  migrations_folder = os.path.join(migrations_root, folder)
  if skip_if_empty:
    if not os.path.exists(migrations_folder):
      _log.debug(
          f'Skipping migrations in {migrations_folder}, it does not exist')
      return
    files = os.listdir(migrations_folder)
    if len(files) == 0:
      _log.debug(f'Skipping migrations in {migrations_folder}, it is empty')
      return
  db_mate = os.path.join(cwd, 'dbmate')
  subprocess.run([
      db_mate,
      '--no-dump-schema',
      '--url',
      # TODO: support rds here
      cred.db_url(),
      '--migrations-dir',
      migrations_folder,
      '--migrations-table',
      f'schema_migrations_{label}',
      'up'
  ]).check_returncode()


def _install_db_and_roles():
  _run_migration(_SuperUserCredential, 'superuser', 'superuser')
  _run_migration(_ImportCredential, 'introspector', 'introspector')
  _run_migration(_ImportCredential, 'provider/aws', 'aws')


def run_tool_migrations(tool_name: str):
  folder = os.path.join('tools', tool_name)
  label = 'tools_' + tool_name
  _run_migration(_SuperUserCredential,
                 os.path.join(folder, 'superuser'),
                 label + '_superuser',
                 skip_if_empty=True)
  _run_migration(_ImportCredential,
                 os.path.join(folder, 'import_user'),
                 label,
                 skip_if_empty=True)


def init_db():
  _install_db_and_roles()


def import_session() -> Session:
  global _import_engine
  if _import_engine is None:
    _import_engine = _ImportCredential.create_engine()
    # Force connection errors early
    _import_engine.connect()
  return sessionmaker(bind=_import_engine)()


def readonly_session() -> Session:
  global _readonly_engine
  if _readonly_engine is None:
    _readonly_engine = _ReadonlyCredential.create_engine()
    # Force connection errors early
    _readonly_engine.connect()
  return sessionmaker(bind=_readonly_engine)()


def db_from_connection(conn) -> Session:
  engine = create_engine('postgresql+psycopg2://', creator=lambda: conn)
  return sessionmaker(bind=engine)()


def scoped_readonly_session(provider_account_id: int) -> Session:
  engine = _ReadonlyScopedCredential.create_engine()
  db = sessionmaker(bind=engine)()
  db.execute('SET introspector.provider_account_id = :provider_account_id',
             {'provider_account_id': provider_account_id})
  return db


@dataclass
class ReadOnlyProviderDB:
  db: Session
  provider_account_id: int


def scope_readonly_session(fn: Callable[[Session], int]) -> ReadOnlyProviderDB:
  engine = _ReadonlyScopedCredential.create_engine()
  db = sessionmaker(bind=engine)()
  provider_account_id = fn(db)
  db.execute('SET introspector.provider_account_id = :provider_account_id',
             {'provider_account_id': provider_account_id})
  return ReadOnlyProviderDB(db=db, provider_account_id=provider_account_id)