-- root pointer ref
-- match
SELECT is_jsonb_valid('{"properties":{"foo":{"$ref":"#"}},"additionalProperties":false}', '{"foo":false}');
-- recursive match
SELECT is_jsonb_valid('{"properties":{"foo":{"$ref":"#"}},"additionalProperties":false}', '{"foo":{"foo":false}}');
-- mismatch
SELECT is_jsonb_valid('{"properties":{"foo":{"$ref":"#"}},"additionalProperties":false}', '{"bar":false}');
-- recursive mismatch
SELECT is_jsonb_valid('{"properties":{"foo":{"$ref":"#"}},"additionalProperties":false}', '{"foo":{"bar":false}}');
-- relative pointer ref to object
-- match
SELECT is_jsonb_valid('{"properties":{"foo":{"type":"integer"},"bar":{"$ref":"#/properties/foo"}}}', '{"bar":3}');
-- mismatch
SELECT is_jsonb_valid('{"properties":{"foo":{"type":"integer"},"bar":{"$ref":"#/properties/foo"}}}', '{"bar":true}');
-- relative pointer ref to array
-- match array
SELECT is_jsonb_valid('{"items":[{"type":"integer"},{"$ref":"#/items/0"}]}', '[1,2]');
-- mismatch array
SELECT is_jsonb_valid('{"items":[{"type":"integer"},{"$ref":"#/items/0"}]}', '[1,"foo"]');
-- nested refs
-- nested ref valid
SELECT is_jsonb_valid('{"definitions":{"a":{"type":"integer"},"b":{"$ref":"#/definitions/a"},"c":{"$ref":"#/definitions/b"}},"$ref":"#/definitions/c"}', '5');
-- nested ref invalid
SELECT is_jsonb_valid('{"definitions":{"a":{"type":"integer"},"b":{"$ref":"#/definitions/a"},"c":{"$ref":"#/definitions/b"}},"$ref":"#/definitions/c"}', '"a"');
-- ref overrides any sibling keywords
-- ref valid
SELECT is_jsonb_valid('{"definitions":{"reffed":{"type":"array"}},"properties":{"foo":{"$ref":"#/definitions/reffed","maxItems":2}}}', '{"foo":[]}');
-- ref valid, maxItems ignored
SELECT is_jsonb_valid('{"definitions":{"reffed":{"type":"array"}},"properties":{"foo":{"$ref":"#/definitions/reffed","maxItems":2}}}', '{"foo":[1,2,3]}');
-- ref invalid
SELECT is_jsonb_valid('{"definitions":{"reffed":{"type":"array"}},"properties":{"foo":{"$ref":"#/definitions/reffed","maxItems":2}}}', '{"foo":"string"}');
-- property named $ref that is not a reference
-- property named $ref valid
SELECT is_jsonb_valid('{"properties":{"$ref":{"type":"string"}}}', '{"$ref":"a"}');
-- property named $ref invalid
SELECT is_jsonb_valid('{"properties":{"$ref":{"type":"string"}}}', '{"$ref":2}');