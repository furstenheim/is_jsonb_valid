\echo Use "Create extension is_jsonb_valid to load this file." \quit

CREATE FUNCTION is_jsonb_valid (jsonb schema, jsonb my_jsonb)
RETURN jsonb
AS "$libdir/jsonb_deep_sum"
LANGUAGE C IMMUTABLE STRICT;
