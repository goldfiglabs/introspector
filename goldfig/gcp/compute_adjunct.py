import logging
from typing import Dict, Generator, List, Tuple

from sqlalchemy import text
from sqlalchemy.orm import Session

from goldfig import db_import_writer, ImportWriter, PathStack
from goldfig.delta.resource import apply_mapped_attrs
from goldfig.gcp.compute import add_images_to_import
from goldfig.gcp.fetch import Proxy
from goldfig.models import ImportJob

_log = logging.getLogger(__name__)


def _find_missing_images(db: Session, provider_account_id: int):
  stmt = text('''
  WITH existing AS (
    SELECT
      to_json(R.uri) AS image_uri
    FROM
      resource AS R,
      resource_attribute AS RA
    WHERE
      R.provider_type = 'image'
      -- technically we don't need this, since URIs are actually universal
      AND R.provider_account_id = :provider_account_id
  )
  SELECT
    Disk.id,
    Disk.name,
    Disk_sourceImage.attr_value AS sourceImage_uri
  FROM
    resource as Disk,
    resource_attribute AS Disk_sourceImage
  WHERE
    Disk.provider_account_id = :provider_account_id
    AND Disk.provider_type = 'disk'
    AND Disk_sourceImage.resource_id = Disk.id
    AND Disk_sourceImage.type = 'provider'
    AND Disk_sourceImage.attr_name = 'sourceImage'
    AND Disk_sourceImage.attr_value::TEXT NOT IN (SELECT image_uri::TEXT FROM existing)
  ''')
  results = db.execute(stmt, {'provider_account_id': provider_account_id})
  images = []
  for result in results:
    uri = result['sourceimage_uri']
    parts = uri.split('/')
    image_id = parts[-1]
    project_index = parts.index('projects')
    project = parts[project_index + 1]
    images.append({'image_id': image_id, 'project': project})
  # De-dupe
  return [dict(item) for item in set(tuple(d.items()) for d in images)]


def _find_adjunct_data(db: Session, proxy: Proxy, writer: ImportWriter,
                       ps: PathStack, provider_account_id: int):
  missing_images = _find_missing_images(db, provider_account_id)
  _log.info(f'missing images {missing_images}')
  add_images_to_import(proxy, writer, ps, missing_images)


def import_adjunct_data(db: Session, import_job: ImportJob, proxy: Proxy):
  provider_account_id = import_job.provider_account_id

  writer = db_import_writer(db,
                            import_job.id,
                            'compute',
                            phase=1,
                            source='base')
  ps = PathStack.from_import_job(import_job)
  _find_adjunct_data(db, proxy, writer, ps, provider_account_id)


def _unpack_endpoint_row(row) -> Tuple[str, Dict, List[Dict]]:
  forward = row['forward_uri']
  uri = f'goldfig/{forward}'
  name = f'endpoint-{row["forward_name"]}'
  raw = {
      'name': name,
  }
  attrs = []

  ip_address = row['ipaddress']
  # TODO: it could be a reference...
  raw['PublicIp'] = ip_address
  attrs.append({'type': 'Endpoint', 'name': 'PublicIp', 'value': ip_address})
  port_range = row['portrange']
  if port_range != '443':
    raise NotImplementedError(f'Not yet supported: {port_range}')
  else:
    port = int(port_range)
    raw['Port'] = port
    attrs.append({'type': 'Endpoint', 'name': 'Port', 'value': port})

  proxy_kind = row['proxykind']
  if proxy_kind != 'compute#targetHttpsProxy':
    raise NotImplementedError(f'Not yet supported: {proxy_kind}')
  else:
    raw['Protocol'] = 'https'
    attrs.append({'type': 'Endpoint', 'name': 'Protocol', 'value': 'https'})

  certificate = row['certificate']
  raw['SSLCertificate'] = certificate
  attrs.append({
      'type': 'Endpoint',
      'name': 'SSLCertificate',
      'value': certificate
  })

  mapped = {'name': name, 'type': 'Endpoint', 'raw': raw, 'uri': uri}
  return uri, mapped, attrs


def _find_endpoints(
    db: Session,
    provider_account_id: int) -> Generator[Tuple[str, Dict, List], None, None]:
  stmt = text('''
    SELECT
      Forward.uri AS forward_uri,
      Forward.name AS forward_name,
      Proxy.uri AS proxy,
      ForwardIP.attr_value AS IPAddress,
      Port.attr_value AS portRange,
      -- This will turn into protocol
      ProxyKind.attr_value AS ProxyKind,
      Certificate.uri as certificate
    FROM
      resource AS Forward
      LEFT JOIN resource_attribute AS ForwardIP
        ON ForwardIP.resource_id = Forward.id
        AND ForwardIP.type = 'provider'
        AND ForwardIP.attr_name = 'IPAddress'
      LEFT JOIN resource_relation AS ForwardsTo
        ON Forward.id = ForwardsTo.resource_id
        AND ForwardsTo.relation = 'forwards-to'
      INNER JOIN resource AS Proxy
        ON ForwardsTo.target_id = Proxy.id
        AND Proxy.provider_type = 'targetHttpsProxy'
      LEFT JOIN resource_attribute AS Port
        ON Port.resource_id = Forward.id
        AND Port.attr_name = 'portRange'
      LEFT JOIN resource_attribute AS ProxyKind
        ON ProxyKind.resource_id = Proxy.id
        AND ProxyKind.attr_name = 'kind'
      LEFT JOIN resource_relation AS ServesCert
        ON ServesCert.resource_id = Proxy.id
        AND ServesCert.relation = 'serves'
      LEFT JOIN resource AS Certificate
        ON ServesCert.target_id = Certificate.id
        AND Certificate.provider_type = 'sslCertificate'
    WHERE
      Forward.provider_type = 'forwardingRule'
      AND Forward.provider_account_id = :provider_account_id
  ''')
  result = db.execute(stmt, {'provider_account_id': provider_account_id})
  for row in result:
    yield _unpack_endpoint_row(row)


def synthesize_endpoints(db: Session, import_job: ImportJob):
  for path, mapped, attrs in _find_endpoints(db,
                                             import_job.provider_account_id):
    apply_mapped_attrs(db,
                       import_job,
                       path,
                       mapped,
                       attrs,
                       source='base',
                       raw_import_id=None)


def synthesize_resources(db: Session, import_job_id: int):
  import_job = db.query(ImportJob).get(import_job_id)
  synthesize_endpoints(db, import_job)
