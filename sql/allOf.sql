-- allOf
-- allOf
SELECT is_jsonb_valid('{"allOf":[{"properties":{"bar":{"type":"integer"}},"required":["bar"]},{"properties":{"foo":{"type":"string"}},"required":["foo"]}]}', '{"foo":"baz","bar":2}');
-- mismatch second
SELECT is_jsonb_valid('{"allOf":[{"properties":{"bar":{"type":"integer"}},"required":["bar"]},{"properties":{"foo":{"type":"string"}},"required":["foo"]}]}', '{"foo":"baz"}');
-- mismatch first
SELECT is_jsonb_valid('{"allOf":[{"properties":{"bar":{"type":"integer"}},"required":["bar"]},{"properties":{"foo":{"type":"string"}},"required":["foo"]}]}', '{"bar":2}');
-- wrong type
SELECT is_jsonb_valid('{"allOf":[{"properties":{"bar":{"type":"integer"}},"required":["bar"]},{"properties":{"foo":{"type":"string"}},"required":["foo"]}]}', '{"foo":"baz","bar":"quux"}');
-- allOf with base schema
-- valid
SELECT is_jsonb_valid('{"properties":{"bar":{"type":"integer"}},"required":["bar"],"allOf":[{"properties":{"foo":{"type":"string"}},"required":["foo"]},{"properties":{"baz":{"type":"null"}},"required":["baz"]}]}', '{"foo":"quux","bar":2,"baz":null}');
-- mismatch base schema
SELECT is_jsonb_valid('{"properties":{"bar":{"type":"integer"}},"required":["bar"],"allOf":[{"properties":{"foo":{"type":"string"}},"required":["foo"]},{"properties":{"baz":{"type":"null"}},"required":["baz"]}]}', '{"foo":"quux","baz":null}');
-- mismatch first allOf
SELECT is_jsonb_valid('{"properties":{"bar":{"type":"integer"}},"required":["bar"],"allOf":[{"properties":{"foo":{"type":"string"}},"required":["foo"]},{"properties":{"baz":{"type":"null"}},"required":["baz"]}]}', '{"bar":2,"baz":null}');
-- mismatch second allOf
SELECT is_jsonb_valid('{"properties":{"bar":{"type":"integer"}},"required":["bar"],"allOf":[{"properties":{"foo":{"type":"string"}},"required":["foo"]},{"properties":{"baz":{"type":"null"}},"required":["baz"]}]}', '{"foo":"quux","bar":2}');
-- mismatch both
SELECT is_jsonb_valid('{"properties":{"bar":{"type":"integer"}},"required":["bar"],"allOf":[{"properties":{"foo":{"type":"string"}},"required":["foo"]},{"properties":{"baz":{"type":"null"}},"required":["baz"]}]}', '{"bar":2}');
-- allOf simple types
-- valid
SELECT is_jsonb_valid('{"allOf":[{"maximum":30},{"minimum":20}]}', '25');
-- mismatch one
SELECT is_jsonb_valid('{"allOf":[{"maximum":30},{"minimum":20}]}', '35');