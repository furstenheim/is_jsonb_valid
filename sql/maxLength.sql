-- maxLength validation
-- shorter is valid
SELECT is_jsonb_valid('{"maxLength":2}', '"f"');
-- exact length is valid
SELECT is_jsonb_valid('{"maxLength":2}', '"fo"');
-- too long is invalid
SELECT is_jsonb_valid('{"maxLength":2}', '"foo"');
-- ignores non-strings
SELECT is_jsonb_valid('{"maxLength":2}', '100');
-- two supplementary Unicode code points is long enough
SELECT is_jsonb_valid('{"maxLength":2}', '"💩💩"');