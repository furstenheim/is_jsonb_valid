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
-- allOf with one empty schema
-- any data is valid
SELECT is_jsonb_valid('{"allOf":[{}]}', '1');
-- allOf with two empty schemas
-- any data is valid
SELECT is_jsonb_valid('{"allOf":[{},{}]}', '1');
-- allOf with the first empty schema
-- number is valid
SELECT is_jsonb_valid('{"allOf":[{},{"type":"number"}]}', '1');
-- string is invalid
SELECT is_jsonb_valid('{"allOf":[{},{"type":"number"}]}', '"foo"');
-- allOf with the last empty schema
-- number is valid
SELECT is_jsonb_valid('{"allOf":[{"type":"number"},{}]}', '1');
-- string is invalid
SELECT is_jsonb_valid('{"allOf":[{"type":"number"},{}]}', '"foo"');
-- nested allOf, to check validation semantics
-- null is valid
SELECT is_jsonb_valid('{"allOf":[{"allOf":[{"type":"null"}]}]}', 'null');
-- anything non-null is invalid
SELECT is_jsonb_valid('{"allOf":[{"allOf":[{"type":"null"}]}]}', '123');
-- allOf combined with anyOf, oneOf
-- allOf: false, anyOf: false, oneOf: false
SELECT is_jsonb_valid('{"allOf":[{"multipleOf":2}],"anyOf":[{"multipleOf":3}],"oneOf":[{"multipleOf":5}]}', '1');
-- allOf: false, anyOf: false, oneOf: true
SELECT is_jsonb_valid('{"allOf":[{"multipleOf":2}],"anyOf":[{"multipleOf":3}],"oneOf":[{"multipleOf":5}]}', '5');
-- allOf: false, anyOf: true, oneOf: false
SELECT is_jsonb_valid('{"allOf":[{"multipleOf":2}],"anyOf":[{"multipleOf":3}],"oneOf":[{"multipleOf":5}]}', '3');
-- allOf: false, anyOf: true, oneOf: true
SELECT is_jsonb_valid('{"allOf":[{"multipleOf":2}],"anyOf":[{"multipleOf":3}],"oneOf":[{"multipleOf":5}]}', '15');
-- allOf: true, anyOf: false, oneOf: false
SELECT is_jsonb_valid('{"allOf":[{"multipleOf":2}],"anyOf":[{"multipleOf":3}],"oneOf":[{"multipleOf":5}]}', '2');
-- allOf: true, anyOf: false, oneOf: true
SELECT is_jsonb_valid('{"allOf":[{"multipleOf":2}],"anyOf":[{"multipleOf":3}],"oneOf":[{"multipleOf":5}]}', '10');
-- allOf: true, anyOf: true, oneOf: false
SELECT is_jsonb_valid('{"allOf":[{"multipleOf":2}],"anyOf":[{"multipleOf":3}],"oneOf":[{"multipleOf":5}]}', '6');
-- allOf: true, anyOf: true, oneOf: true
SELECT is_jsonb_valid('{"allOf":[{"multipleOf":2}],"anyOf":[{"multipleOf":3}],"oneOf":[{"multipleOf":5}]}', '30');