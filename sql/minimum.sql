-- minimum validation
-- above the minimum is valid
SELECT is_jsonb_valid('{"minimum":1.1}', '2.6');
-- boundary point is valid
SELECT is_jsonb_valid('{"minimum":1.1}', '1.1');
-- below the minimum is invalid
SELECT is_jsonb_valid('{"minimum":1.1}', '0.6');
-- ignores non-numbers
SELECT is_jsonb_valid('{"minimum":1.1}', '"x"');
-- exclusiveMinimum validation
-- above the minimum is still valid
SELECT is_jsonb_valid('{"minimum":1.1,"exclusiveMinimum":true}', '1.2');
-- boundary point is invalid
SELECT is_jsonb_valid('{"minimum":1.1,"exclusiveMinimum":true}', '1.1');