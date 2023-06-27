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
-- anyOf complex types
-- first anyOf valid (complex)
SELECT is_jsonb_valid('{"anyOf":[{"properties":{"bar":{"type":"integer"}},"required":["bar"]},{"properties":{"foo":{"type":"string"}},"required":["foo"]}]}', '{"bar":2}');
-- second anyOf valid (complex)
SELECT is_jsonb_valid('{"anyOf":[{"properties":{"bar":{"type":"integer"}},"required":["bar"]},{"properties":{"foo":{"type":"string"}},"required":["foo"]}]}', '{"foo":"baz"}');
-- both anyOf valid (complex)
SELECT is_jsonb_valid('{"anyOf":[{"properties":{"bar":{"type":"integer"}},"required":["bar"]},{"properties":{"foo":{"type":"string"}},"required":["foo"]}]}', '{"foo":"baz","bar":2}');
-- neither anyOf valid (complex)
SELECT is_jsonb_valid('{"anyOf":[{"properties":{"bar":{"type":"integer"}},"required":["bar"]},{"properties":{"foo":{"type":"string"}},"required":["foo"]}]}', '{"foo":2,"bar":"quux"}');
-- anyOf with one empty schema
-- string is valid
SELECT is_jsonb_valid('{"anyOf":[{"type":"number"},{}]}', '"foo"');
-- number is valid
SELECT is_jsonb_valid('{"anyOf":[{"type":"number"},{}]}', '123');
-- nested anyOf, to check validation semantics
-- null is valid
SELECT is_jsonb_valid('{"anyOf":[{"anyOf":[{"type":"null"}]}]}', 'null');
-- anything non-null is invalid
SELECT is_jsonb_valid('{"anyOf":[{"anyOf":[{"type":"null"}]}]}', '123');