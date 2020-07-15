import logging

from sqlalchemy import text
from sqlalchemy.orm import Session

from goldfig import ImportWriter, PathStack
from goldfig.aws.ec2 import add_amis_to_import_job
from goldfig.aws.fetch import Proxy
from goldfig.models import ImportJob

_log = logging.getLogger(__name__)


def _find_missing_amis(db: Session, provider_account_id: int):
  # Selects AMIs and their regions from all the AMIs in use by VMs
  # and not already in our db
  stmt = text('''
    SELECT
      DISTINCT ON (ImageId.attr_value#>> '{}', VMRegion.attr_value#>>'{}')
      ImageId.attr_value#>> '{}' AS ami,
      VMRegion.attr_value#>>'{}' AS region
    FROM
      resource AS VM
      LEFT JOIN resource_attribute AS VMRegion
        ON VMRegion.resource_id = VM.id
        AND VMRegion.type = 'Metadata'
        AND VMRegion.attr_name = 'Region'
      LEFT JOIN resource_attribute AS ImageId
        ON ImageId.resource_id = VM.id
        AND ImageId.type = 'provider'
        AND ImageId.attr_name = 'ImageId'
      LEFT OUTER JOIN resource AS Image
        ON Image.provider_type = 'Image'
        AND Image.name = ImageId.attr_value#>> '{}'
      LEFT JOIN resource_attribute AS ImageRegion
        ON ImageRegion.resource_id = Image.id
        AND ImageRegion.type = 'Metadata'
        AND ImageRegion.attr_name = 'Region'
        AND ImageRegion.attr_value = VMRegion.attr_value
      LEFT JOIN resource_attribute AS ImagePublic
        ON ImagePublic.resource_id = Image.id
        AND ImagePublic.type = 'Image'
        AND ImagePublic.attr_name = 'Public'
    WHERE
      VM.provider_type = 'Instance'
      AND VM.provider_account_id = :provider_account_id
      AND COALESCE((ImagePublic.attr_value#>>'{}')::bool, true)
  ''')
  results = db.execute(stmt, {'provider_account_id': provider_account_id})
  regional_amis = {}
  for result in results:
    region = result['region']
    ami = result['ami']
    amis = regional_amis.get(region, [])
    amis.append(ami)
    regional_amis[region] = amis
  _log.info(f'regional_amis: {regional_amis}')
  return regional_amis


def find_adjunct_data(db: Session, proxy: Proxy, writer: ImportWriter,
                      import_job: ImportJob, ps: PathStack, account_id: str):
  regional_amis = _find_missing_amis(db, import_job.provider_account_id)
  for region, amis in regional_amis.items():
    add_amis_to_import_job(proxy, writer, ps, region, amis)
