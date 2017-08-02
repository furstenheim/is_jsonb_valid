-- maxItems validation
-- shorter is valid
SELECT is_jsonb_valid('{"maxItems":2}', '[1]');
-- exact length is valid
SELECT is_jsonb_valid('{"maxItems":2}', '[1,2]');
-- too long is invalid
SELECT is_jsonb_valid('{"maxItems":2}', '[1,2,3]');
-- ignores non-arrays
SELECT is_jsonb_valid('{"maxItems":2}', '"foobar"');