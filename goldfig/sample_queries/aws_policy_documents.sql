SELECT
  P.uri AS PolicyArn,
  PV.document AS PolicyDocument
FROM
  aws_iam_policy AS P
  INNER JOIN aws_iam_policyversion AS PV
    ON PV.resource_id = P._default_policyversion_id