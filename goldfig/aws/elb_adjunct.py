from typing import Any, Generator, Dict, List, Tuple

from sqlalchemy import text
from sqlalchemy.orm import Session

from goldfig.delta.resource import apply_mapped_attrs
from goldfig.models import ImportJob


def _unpack_endpoint_row(row) -> Tuple[str, Dict, List]:
  listener_uri = row['listener']
  uri = f'goldfig/{listener_uri}'
  name = f'endpoint-{row["elbname"]}-{row["port"]}'
  raw: Dict[str, Any] = {'name': name}
  attrs = []

  dns_name = row['dnsname']
  raw['DNSName'] = dns_name
  attrs.append({'type': 'Endpoint', 'name': 'DNSName', 'value': dns_name})

  port = int(row['port'])
  raw['Port'] = port
  attrs.append({'type': 'Endpoint', 'name': 'Port', 'value': port})

  protocol = row['protocol'].lower()
  raw['Protocol'] = protocol
  attrs.append({'type': 'Endpoint', 'name': 'Protocol', 'value': protocol})

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
      Listener.uri AS Listener,
      ListenerPort.attr_value as Port,
      ListenerProtocol.attr_value as Protocol,
      DNSName.attr_value AS DNSName,
      ELB.name AS ELBName,
      SSLCertificate.attr_value AS certificate
    FROM
      resource AS Listener
      LEFT JOIN resource_attribute AS ListenerPort
        ON ListenerPort.resource_id = Listener.id
        AND ListenerPort.type = 'provider'
        AND ListenerPort.attr_name = 'LoadBalancerPort'
      LEFT JOIN resource_attribute AS ListenerProtocol
        ON ListenerProtocol.resource_id = Listener.id
        AND ListenerProtocol.type = 'provider'
        AND ListenerProtocol.attr_name = 'Protocol'
      LEFT JOIN resource_attribute AS SSLCertificate
        ON SSLCertificate.resource_id = Listener.id
        AND SSLCertificate.type = 'provider'
        AND SSLCertificate.attr_name = 'SSLCertificateId'
      LEFT JOIN resource_relation AS ELBServes
        ON ELBServes.resource_id = Listener.id
        AND ELBServes.relation = 'forwards-to'
      LEFT JOIN resource AS ELB
        ON ELB.id = ELBServes.target_id
        AND ELB.provider_type = 'elb'
      LEFT JOIN resource_attribute AS ELBScheme
        ON ELBScheme.resource_id = ELB.id
        AND ELBScheme.type = 'provider'
        AND ELBScheme.attr_name = 'Scheme'
      LEFT JOIN resource_attribute AS DNSName
        ON DNSName.resource_id = ELB.id
        AND DNSName.type = 'provider'
        AND DNSName.attr_name = 'DNSName'
    WHERE
      Listener.provider_type = 'Listener'
      AND Listener.provider_account_id = :provider_account_id
      AND (
        ELBScheme.attr_value = '""'::jsonb
        OR ELBScheme.attr_value = '"internet-facing"'::jsonb
      )
  ''')
  result = db.execute(stmt, {'provider_account_id': provider_account_id})
  for row in result:
    yield _unpack_endpoint_row(row)


def synthesize_endpoints(db: Session, import_job: ImportJob) -> None:
  for path, mapped, attrs in _find_endpoints(db,
                                             import_job.provider_account_id):
    apply_mapped_attrs(db, import_job, path, mapped, attrs, raw_import_id=None)


def synthesize_resources(db: Session, import_job_id: int) -> None:
  import_job = db.query(ImportJob).get(import_job_id)
  synthesize_endpoints(db, import_job)
