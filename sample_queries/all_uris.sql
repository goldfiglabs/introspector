SELECT PA.provider,
  PA.name,
  R.uri
FROM resource AS R
  LEFT JOIN provider_account AS PA ON R.provider_account_id = PA.id