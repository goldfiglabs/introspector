-- migrate:up
CREATE OR REPLACE FUNCTION unpack_maybe_array(val jsonb)
RETURNS TABLE (value jsonb) AS
$$
	SELECT
		val AS value
	WHERE
		jsonb_typeof(val) != 'array'
	UNION
	SELECT
		V.value as value
	FROM
		jsonb_array_elements(val) AS V
	WHERE
		jsonb_typeof(val) = 'array'
$$
language SQL;

-- migrate:down
DROP FUNCTION unpack_maybe_array;
