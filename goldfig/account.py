from typing import Dict

from sqlalchemy.orm import Session

from goldfig.models import ProviderAccount


def _delete_delta_log(db: Session, provider_account_id: int, report):
  result = db.execute(
      '''
    DELETE FROM resource_relation_attribute_delta
    USING
      resource_relation_delta AS RRD,
      import_job AS IJ
    WHERE
      resource_relation_delta_id = RRD.id
      AND RRD.import_job_id = IJ.id
      AND IJ.provider_account_id = :provider_account_id
  ''', {'provider_account_id': provider_account_id})
  report['resource_relation_attribute_delta'] = result.rowcount
  result = db.execute(
      '''
    DELETE FROM resource_relation_delta
    USING
      import_job AS IJ
    WHERE
      import_job_id = IJ.id
      AND IJ.provider_account_id = :provider_account_id
  ''', {'provider_account_id': provider_account_id})
  report['resource_relation_delta'] = result.rowcount
  result = db.execute(
      '''
    DELETE FROM resource_attribute_delta
    USING
      resource_delta AS RD,
      import_job AS IJ
    WHERE
      resource_delta_id = RD.id
      AND RD.import_job_id = IJ.id
      AND IJ.provider_account_id = :provider_account_id
  ''', {'provider_account_id': provider_account_id})
  report['resource_attribute_delta'] = result.rowcount
  result = db.execute(
      '''
    DELETE FROM resource_delta
    USING
      import_job AS IJ
    WHERE
      import_job_id = IJ.id
      AND IJ.provider_account_id = :provider_account_id
  ''', {'provider_account_id': provider_account_id})
  report['resource_delta'] = result.rowcount


def _delete_resources(db: Session, provider_account_id: int, report):
  result = db.execute(
      '''
    DELETE FROM resource_relation_attribute
    USING
      resource_relation AS RR,
      resource AS R
    WHERE
      relation_id = RR.id
      AND RR.resource_id = R.id
      AND R.provider_account_id = :provider_account_id
  ''', {'provider_account_id': provider_account_id})
  report['resource_relation_attribute'] = result.rowcount
  result = db.execute(
      '''
    DELETE FROM resource_relation
    USING
      resource AS R
    WHERE
      resource_id = R.id
      AND R.provider_account_id = :provider_account_id
  ''', {'provider_account_id': provider_account_id})
  report['resource_relation'] = result.rowcount
  result = db.execute(
      '''
    DELETE FROM resource_attribute
    USING
      resource AS R
    WHERE
      resource_id = R.id
      AND R.provider_account_id = :provider_account_id
  ''', {'provider_account_id': provider_account_id})
  report['resource_attribute'] = result.rowcount
  db.flush()
  db.execute(
      '''
    DELETE FROM resource
    WHERE
      provider_account_id = :provider_account_id
  ''', {'provider_account_id': provider_account_id})
  report['resource'] = result.rowcount


def _delete_imports(db: Session, provider_account_id: int, report):
  result = db.execute(
      '''
    DELETE FROM mapped_uri
    USING
      import_job AS IJ
    WHERE
      import_job_id = IJ.id
      AND IJ.provider_account_id = :provider_account_id
  ''', {'provider_account_id': provider_account_id})
  report['mapped_uri'] = result.rowcount
  result = db.execute(
      '''
    DELETE FROM raw_import
    USING
      import_job AS IJ
    WHERE
      import_job_id = IJ.id
      AND IJ.provider_account_id = :provider_account_id
  ''', {'provider_account_id': provider_account_id})
  report['raw_import'] = result.rowcount
  result = db.execute(
      '''
    DELETE FROM import_job
    WHERE
      provider_account_id = :provider_account_id
  ''', {'provider_account_id': provider_account_id})
  report['import_job'] = result.rowcount


def _delete_provider_account(db: Session, provider_account_id: int, report):
  result = db.execute(
      '''
    DELETE FROM provider_credential
    WHERE
      provider_id = :provider_account_id
  ''', {'provider_account_id': provider_account_id})
  report['provider_credential'] = result.rowcount
  result = db.execute(
      '''
    DELETE FROM provider_account
    WHERE
      id = :provider_account_id
  ''', {'provider_account_id': provider_account_id})
  report['provider_account'] = result.rowcount


def _reset_imports(db: Session, provider_account_id: int, report: Dict[str,
                                                                       int]):
  result = db.execute(
      '''
    DELETE FROM mapped_uri
    USING
      raw_import AS RI,
      import_job AS IJ
    WHERE
      raw_import_id = RI.id
      AND RI.import_job_id = IJ.id
      AND IJ.provider_account_id = :provider_account_id
  ''', {'provider_account_id': provider_account_id})
  report['mapped_uri'] = result.rowcount
  result = db.execute(
      '''
    DELETE FROM raw_import
    USING
      import_job as IJ
    WHERE
      phase > 0
      AND import_job_id = IJ.id
      AND IJ.provider_account_id = :provider_account_id
  ''', {'provider_account_id': provider_account_id})
  report['import_job'] = result.rowcount
  result = db.execute(
      '''
    UPDATE raw_import
    SET mapped = false
    FROM import_job AS IJ
    WHERE
      import_job_id = IJ.id
      AND IJ.provider_account_id = :provider_account_id
  ''', {'provider_account_id': provider_account_id})
  report['raw_import'] = result.rowcount


def reset_account(db: Session, provider_account_id: int):
  report = {}
  _delete_delta_log(db, provider_account_id, report)
  _delete_resources(db, provider_account_id, report)
  _reset_imports(db, provider_account_id, report)
  return report


def delete_account(db: Session, account: ProviderAccount):
  report = {}
  _delete_delta_log(db, account.id, report)
  _delete_resources(db, account.id, report)
  _delete_imports(db, account.id, report)
  _delete_provider_account(db, account.id, report)
  return report
