from sqlalchemy.orm import Session

from goldfig.tools.cis.base import Profile, ThreeTierBenchmark, TierTag


class DiskEncrypted(ThreeTierBenchmark):
  def __init__(self):
    super().__init__(profile=Profile.LEVEL1,
                     description='Require disks to have encryption enabled',
                     reference_ids=['1.5', '1.6'])

  def exec(self, db: Session, provider_account_id: int, tier_tag: TierTag):
    result = db.execute(
        '''
      SELECT
        Disk.uri AS uri
      FROM
        resource AS Disk
        LEFT JOIN resource_attribute AS Encryption ON
          Encryption.resource_id = Disk.id
          AND Encryption.type = 'Disk'
          AND Encryption.attr_name = 'Encrypted'
        LEFT JOIN resource_attribute AS Tags ON
          Tags.resource_id = Disk.id
          AND Tags.type = 'Metadata'
          AND Tags.attr_name = 'Tags'
      WHERE
        Disk.category = 'Disk'
        AND Disk.provider_account_id = :provider_account_id
        AND COALESCE(Encryption.attr_value, 'false'::jsonb) != 'true'::jsonb
        AND Tags.attr_value->>:role_key = :role_value
      ''', {
            'provider_account_id': provider_account_id,
            'role_key': tier_tag[0],
            'role_value': tier_tag[1]
        })
    return [row['uri'] for row in result]

  def exec_explain(self, db: Session, provider_account_id: int,
                   tier_tag: TierTag) -> str:
    results = self.exec(db, provider_account_id, tier_tag)
    key, value = tier_tag
    nl = '\n'
    if len(results) == 0:
      desc = 'NONE'
    else:
      desc = '\n\t'.join(results)
    return f'URIs of unencrypted disks tagged {key}: {value}{nl}{desc}'


class PublicImage(ThreeTierBenchmark):
  def __init__(self):
    super().__init__(profile=Profile.LEVEL1,
                     description='Require any custom images to be private',
                     reference_ids=['1.7', '1.8'])

  # TODO: don't flag publicly owned images as a problem

  def exec(self, db: Session, provider_account_id: int, tier_tag: TierTag):
    results = db.execute(
        '''
    SELECT
      ARRAY_AGG(VM.uri) AS vm_uris,
      Image.uri AS image_uri,
      Image_Public.attr_value::BOOLEAN AS is_public,
      IsThirdParty.attr_value::BOOLEAN AS is_thirdparty,
      Image.id IS NULL AS missing
    FROM
      resource as VM
      LEFT OUTER JOIN resource_relation AS Imaged
        ON Imaged.resource_id = VM.id
        AND Imaged.relation = 'imaged'
      LEFT JOIN resource AS Image
        ON Imaged.target_id = Image.id
        AND Image.category = 'Image'
      LEFT JOIN resource_attribute AS Image_Public
        ON Image_Public.resource_id = Image.id
        AND Image_Public.type = 'Image'
        AND Image_Public.attr_name = 'Public'
      LEFT JOIN resource_attribute AS IsThirdParty
        ON IsThirdParty.resource_id = Image.id
        AND IsThirdParty.type = 'Image'
        AND IsThirdParty.attr_name = 'IsThirdParty'
      LEFT JOIN resource_attribute AS Tags
        ON Tags.resource_id = VM.id
        AND Tags.type = 'Metadata'
        AND Tags.attr_name = 'Tags'
    WHERE
      VM.provider_account_id = :provider_account_id
      AND VM.category = 'VMInstance'
      AND Tags.attr_value->>:role_key = :role_value
      AND COALESCE(IsThirdParty.attr_value, 'false'::jsonb) != 'true'::jsonb
      AND COALESCE(Image_Public.attr_value, 'true'::jsonb) != 'false'::jsonb
    GROUP BY
      Image.id, Image_Public.id, IsThirdParty.id
    ''', {
            'provider_account_id': provider_account_id,
            'role_key': tier_tag[0],
            'role_value': tier_tag[1]
        })
    return [
        {
            'vm_uris': row['vm_uris'],
            'image_uri': '<MISSING>' if row['missing'] else row['image_uri'],
            #'status': '<MISSING>' if row['missing'] else row['is_public']
        } for row in results
    ]

  def exec_explain(self, db: Session, provider_account_id: int,
                   tier_tag: TierTag) -> str:
    results = self.exec(db, provider_account_id, tier_tag)
    key, value = tier_tag
    nl = '\n'
    row_desc = lambda row: f'Image URI: {row["image_uri"]}, VMs where it\'s used: {", ".join(row["vm_uris"])}'
    rows = list(map(row_desc, results))
    if len(rows) == 0:
      desc = 'NONE'
    else:
      desc = '\n\t'.join(rows)
    return f'Public, Custom images assigned to VMs tagged {key}: {value}{nl}{desc}'


class HttpsEndpoints(ThreeTierBenchmark):
  def __init__(self):
    super().__init__(profile=Profile.LEVEL1,
                     description='SSL endpoints have certs',
                     reference_ids=['1.9', '1.12'])

  def exec(self, db: Session, provider_account_id: int, tier_tag: TierTag):
    results = db.execute(
        '''
      SELECT
        Endpoint.uri AS endpoint_uri,
        Port.attr_value AS port,
        Protocol.attr_value AS Protocol
      FROM
        resource AS Endpoint
        LEFT JOIN resource_attribute AS Port
          ON Port.resource_id = Endpoint.id
          AND Port.type = 'Endpoint'
          AND Port.attr_name = 'Port'
        LEFT JOIN resource_attribute AS Protocol
          ON Protocol.resource_id = Endpoint.id
          AND Protocol.type = 'Endpoint'
          AND Protocol.attr_name = 'Protocol'
        LEFT OUTER JOIN resource_attribute AS SSLCertificate
          ON SSLCertificate.resource_id = Endpoint.id
          AND SSLCertificate.type = 'Endpoint'
          AND SSLCertificate.attr_name = 'SSLCertificate'
        LEFT JOIN resource_attribute AS Tags
          ON Tags.resource_id = Endpoint.id
          AND Tags.type = 'Metadata'
          AND Tags.attr_name = 'Tags'
      WHERE
        Endpoint.category = 'Endpoint'
        AND Endpoint.provider_account_id = :provider_account_id
        AND COALESCE(SSLCertificate.attr_value, 'null'::jsonb) = 'null'::jsonb
        AND Tags.attr_value->>:role_key = :role_value
    ''', {
            'provider_account_id': provider_account_id,
            'role_key': tier_tag[0],
            'role_value': tier_tag[1]
        })
    return [{
        'endpoint_uri': row['endpoint_uri'],
        'port': row['port'],
        'protcol': row['protocol']
    } for row in results]

  def exec_explain(self, db: Session, provider_account_id: int,
                   tier_tag: TierTag) -> str:
    results = self.exec(db, provider_account_id, tier_tag)
    key, value = tier_tag
    nl = '\n'
    if len(results) == 0:
      desc = 'NONE'
    else:
      '\n\t'.join(lambda row: row['endpoint_uri'], results)
    return f'Endpoints tagged {key}: {value} that are missing SSL Certificates{nl}{desc}'
