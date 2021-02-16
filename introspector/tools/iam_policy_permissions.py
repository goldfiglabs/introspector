from typing import Tuple

from sqlalchemy.orm import Session


def find_permissions(db: Session, policies: Tuple[str]):
  query = f'''
    SELECT
      A.value AS action,
      ARRAY_AGG(P.policyname) AS policies
    FROM
      aws_iam_policy AS P
      INNER JOIN aws_iam_policyversion AS PV
        ON PV._policy_id = P._id
        AND PV.isdefaultversion = true
      CROSS JOIN LATERAL unpack_maybe_array(PV.document -> 'Statement') AS S
      CROSS JOIN LATERAL unpack_maybe_array(S.value -> 'Action') AS A
    WHERE
      P.policyname IN :policies
      AND S.value ->> 'Effect' = 'Allow'
	    AND S.value -> 'Condition' IS NULL
    GROUP BY A.value
    ORDER BY A.value
    '''
  return db.execute(query, {'policies': policies})
