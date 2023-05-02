-- minimum validation
-- above the minimum is valid
SELECT is_jsonb_valid('{"minimum":1.1}', '2.6');
-- boundary point is valid
SELECT is_jsonb_valid('{"minimum":1.1}', '1.1');
-- below the minimum is invalid
SELECT is_jsonb_valid('{"minimum":1.1}', '0.6');
-- ignores non-numbers
SELECT is_jsonb_valid('{"minimum":1.1}', '"x"');
-- minimum validation (explicit false exclusivity)
-- above the minimum is valid
SELECT is_jsonb_valid('{"minimum":1.1,"exclusiveMinimum":false}', '2.6');
-- boundary point is valid
SELECT is_jsonb_valid('{"minimum":1.1,"exclusiveMinimum":false}', '1.1');
-- below the minimum is invalid
SELECT is_jsonb_valid('{"minimum":1.1,"exclusiveMinimum":false}', '0.6');
-- ignores non-numbers
SELECT is_jsonb_valid('{"minimum":1.1,"exclusiveMinimum":false}', '"x"');
-- exclusiveMinimum validation
-- above the minimum is still valid
SELECT is_jsonb_valid('{"minimum":1.1,"exclusiveMinimum":true}', '1.2');
-- boundary point is invalid
SELECT is_jsonb_valid('{"minimum":1.1,"exclusiveMinimum":true}', '1.1');
-- minimum validation with signed integer
-- negative above the minimum is valid
SELECT is_jsonb_valid('{"minimum":-2}', '-1');
-- positive above the minimum is valid
SELECT is_jsonb_valid('{"minimum":-2}', '0');
-- boundary point is valid
SELECT is_jsonb_valid('{"minimum":-2}', '-2');
-- boundary point with float is valid
SELECT is_jsonb_valid('{"minimum":-2}', '-2');
-- float below the minimum is invalid
SELECT is_jsonb_valid('{"minimum":-2}', '-2.0001');
-- int below the minimum is invalid
SELECT is_jsonb_valid('{"minimum":-2}', '-3');
-- ignores non-numbers
SELECT is_jsonb_valid('{"minimum":-2}', '"x"');