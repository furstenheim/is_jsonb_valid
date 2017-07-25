\echo Use "Create extension is_jsonb_valid to load this file." \quit

CREATE FUNCTION is_jsonb_valid (my_schema jsonb, my_jsonb jsonb)
RETURNS boolean
AS '$libdir/is_jsonb_valid'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION jsonb_get2 (my_schema jsonb)
RETURNS jsonb
AS '$libdir/is_jsonb_valid'
LANGUAGE C IMMUTABLE STRICT;
