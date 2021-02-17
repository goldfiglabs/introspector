SELECT
  P.uri AS PolicyArn,
  PV.document AS PolicyDocument
FROM
  aws_iam_policy AS P
  INNER JOIN aws_iam_policyversion AS PV
    ON PV._policy_id = P._id
    AND PV.isdefaultversion = true