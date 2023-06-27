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
-- oneOf complex types
-- first oneOf valid (complex)
SELECT is_jsonb_valid('{"oneOf":[{"properties":{"bar":{"type":"integer"}},"required":["bar"]},{"properties":{"foo":{"type":"string"}},"required":["foo"]}]}', '{"bar":2}');
-- second oneOf valid (complex)
SELECT is_jsonb_valid('{"oneOf":[{"properties":{"bar":{"type":"integer"}},"required":["bar"]},{"properties":{"foo":{"type":"string"}},"required":["foo"]}]}', '{"foo":"baz"}');
-- both oneOf valid (complex)
SELECT is_jsonb_valid('{"oneOf":[{"properties":{"bar":{"type":"integer"}},"required":["bar"]},{"properties":{"foo":{"type":"string"}},"required":["foo"]}]}', '{"foo":"baz","bar":2}');
-- neither oneOf valid (complex)
SELECT is_jsonb_valid('{"oneOf":[{"properties":{"bar":{"type":"integer"}},"required":["bar"]},{"properties":{"foo":{"type":"string"}},"required":["foo"]}]}', '{"foo":2,"bar":"quux"}');
-- oneOf with empty schema
-- one valid - valid
SELECT is_jsonb_valid('{"oneOf":[{"type":"number"},{}]}', '"foo"');
-- both valid - invalid
SELECT is_jsonb_valid('{"oneOf":[{"type":"number"},{}]}', '123');
-- oneOf with required
-- both invalid - invalid
SELECT is_jsonb_valid('{"type":"object","oneOf":[{"required":["foo","bar"]},{"required":["foo","baz"]}]}', '{"bar":2}');
-- first valid - valid
SELECT is_jsonb_valid('{"type":"object","oneOf":[{"required":["foo","bar"]},{"required":["foo","baz"]}]}', '{"foo":1,"bar":2}');
-- second valid - valid
SELECT is_jsonb_valid('{"type":"object","oneOf":[{"required":["foo","bar"]},{"required":["foo","baz"]}]}', '{"foo":1,"baz":3}');
-- both valid - invalid
SELECT is_jsonb_valid('{"type":"object","oneOf":[{"required":["foo","bar"]},{"required":["foo","baz"]}]}', '{"foo":1,"bar":2,"baz":3}');
-- oneOf with missing optional property
-- first oneOf valid
SELECT is_jsonb_valid('{"oneOf":[{"properties":{"bar":{},"baz":{}},"required":["bar"]},{"properties":{"foo":{}},"required":["foo"]}]}', '{"bar":8}');
-- second oneOf valid
SELECT is_jsonb_valid('{"oneOf":[{"properties":{"bar":{},"baz":{}},"required":["bar"]},{"properties":{"foo":{}},"required":["foo"]}]}', '{"foo":"foo"}');
-- both oneOf valid
SELECT is_jsonb_valid('{"oneOf":[{"properties":{"bar":{},"baz":{}},"required":["bar"]},{"properties":{"foo":{}},"required":["foo"]}]}', '{"foo":"foo","bar":8}');
-- neither oneOf valid
SELECT is_jsonb_valid('{"oneOf":[{"properties":{"bar":{},"baz":{}},"required":["bar"]},{"properties":{"foo":{}},"required":["foo"]}]}', '{"baz":"quux"}');
-- nested oneOf, to check validation semantics
-- null is valid
SELECT is_jsonb_valid('{"oneOf":[{"oneOf":[{"type":"null"}]}]}', 'null');
-- anything non-null is invalid
SELECT is_jsonb_valid('{"oneOf":[{"oneOf":[{"type":"null"}]}]}', '123');