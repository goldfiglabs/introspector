SELECT
  DISTINCT(FV.version)
FROM
  aws_lambda_alias AS A
  INNER JOIN aws_lambda_alias_functionversion AS AFV
    ON A._id = AFV.alias_id
  INNER JOIN aws_lambda_functionversion AS FV
    ON AFV.functionversion_id = FV._id