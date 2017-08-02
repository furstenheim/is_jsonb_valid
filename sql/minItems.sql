-- minItems validation
-- longer is valid
SELECT is_jsonb_valid('{"minItems":1}', '[1,2]');
-- exact length is valid
SELECT is_jsonb_valid('{"minItems":1}', '[1]');
-- too short is invalid
SELECT is_jsonb_valid('{"minItems":1}', '[]');
-- ignores non-arrays
SELECT is_jsonb_valid('{"minItems":1}', '""');