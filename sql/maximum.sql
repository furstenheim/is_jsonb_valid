-- maximum validation
-- below the maximum is valid
SELECT is_jsonb_valid('{"maximum":3}', '2.6');
-- boundary point is valid
SELECT is_jsonb_valid('{"maximum":3}', '3');
-- above the maximum is invalid
SELECT is_jsonb_valid('{"maximum":3}', '3.5');
-- ignores non-numbers
SELECT is_jsonb_valid('{"maximum":3}', '"x"');
-- exclusiveMaximum validation
-- below the maximum is still valid
SELECT is_jsonb_valid('{"maximum":3,"exclusiveMaximum":true}', '2.2');
-- boundary point is invalid
SELECT is_jsonb_valid('{"maximum":3,"exclusiveMaximum":true}', '3');