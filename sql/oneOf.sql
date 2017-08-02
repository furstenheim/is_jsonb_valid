-- oneOf
-- first oneOf valid
SELECT is_jsonb_valid('{"oneOf":[{"type":"integer"},{"minimum":2}]}', '1');
-- second oneOf valid
SELECT is_jsonb_valid('{"oneOf":[{"type":"integer"},{"minimum":2}]}', '2.5');
-- both oneOf valid
SELECT is_jsonb_valid('{"oneOf":[{"type":"integer"},{"minimum":2}]}', '3');
-- neither oneOf valid
SELECT is_jsonb_valid('{"oneOf":[{"type":"integer"},{"minimum":2}]}', '1.5');
-- oneOf with base schema
-- mismatch base schema
SELECT is_jsonb_valid('{"type":"string","oneOf":[{"minLength":2},{"maxLength":4}]}', '3');
-- one oneOf valid
SELECT is_jsonb_valid('{"type":"string","oneOf":[{"minLength":2},{"maxLength":4}]}', '"foobar"');
-- both oneOf valid
SELECT is_jsonb_valid('{"type":"string","oneOf":[{"minLength":2},{"maxLength":4}]}', '"foo"');