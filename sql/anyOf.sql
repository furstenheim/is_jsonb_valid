-- anyOf
-- first anyOf valid
SELECT is_jsonb_valid('{"anyOf":[{"type":"integer"},{"minimum":2}]}', '1');
-- second anyOf valid
SELECT is_jsonb_valid('{"anyOf":[{"type":"integer"},{"minimum":2}]}', '2.5');
-- both anyOf valid
SELECT is_jsonb_valid('{"anyOf":[{"type":"integer"},{"minimum":2}]}', '3');
-- neither anyOf valid
SELECT is_jsonb_valid('{"anyOf":[{"type":"integer"},{"minimum":2}]}', '1.5');
-- anyOf with base schema
-- mismatch base schema
SELECT is_jsonb_valid('{"type":"string","anyOf":[{"maxLength":2},{"minLength":4}]}', '3');
-- one anyOf valid
SELECT is_jsonb_valid('{"type":"string","anyOf":[{"maxLength":2},{"minLength":4}]}', '"foobar"');
-- both anyOf invalid
SELECT is_jsonb_valid('{"type":"string","anyOf":[{"maxLength":2},{"minLength":4}]}', '"foo"');