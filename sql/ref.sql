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
SELECT is_jsonb_valid('{"definitions":{"a":{"type":"integer"},"b":{"$ref":"#/definitions/a"},"c":{"$ref":"#/definitions/b"}},"allOf":[{"$ref":"#/definitions/c"}]}', '5');
-- nested ref invalid
SELECT is_jsonb_valid('{"definitions":{"a":{"type":"integer"},"b":{"$ref":"#/definitions/a"},"c":{"$ref":"#/definitions/b"}},"allOf":[{"$ref":"#/definitions/c"}]}', '"a"');
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
-- property named $ref, containing an actual $ref
-- property named $ref valid
SELECT is_jsonb_valid('{"properties":{"$ref":{"$ref":"#/definitions/is-string"}},"definitions":{"is-string":{"type":"string"}}}', '{"$ref":"a"}');
-- property named $ref invalid
SELECT is_jsonb_valid('{"properties":{"$ref":{"$ref":"#/definitions/is-string"}},"definitions":{"is-string":{"type":"string"}}}', '{"$ref":2}');
-- naive replacement of $ref with its destination is not correct
-- do not evaluate the $ref inside the enum, matching any string
SELECT is_jsonb_valid('{"definitions":{"a_string":{"type":"string"}},"enum":[{"$ref":"#/definitions/a_string"}]}', '"this is a string"');
-- match the enum exactly
SELECT is_jsonb_valid('{"definitions":{"a_string":{"type":"string"}},"enum":[{"$ref":"#/definitions/a_string"}]}', '{"$ref":"#/definitions/a_string"}');
-- id with file URI still resolves pointers - *nix
-- number is valid
SELECT is_jsonb_valid('{"id":"file:///folder/file.json","definitions":{"foo":{"type":"number"}},"allOf":[{"$ref":"#/definitions/foo"}]}', '1');
-- non-number is invalid
SELECT is_jsonb_valid('{"id":"file:///folder/file.json","definitions":{"foo":{"type":"number"}},"allOf":[{"$ref":"#/definitions/foo"}]}', '"a"');
-- id with file URI still resolves pointers - windows
-- number is valid
SELECT is_jsonb_valid('{"id":"file:///c:/folder/file.json","definitions":{"foo":{"type":"number"}},"allOf":[{"$ref":"#/definitions/foo"}]}', '1');
-- non-number is invalid
SELECT is_jsonb_valid('{"id":"file:///c:/folder/file.json","definitions":{"foo":{"type":"number"}},"allOf":[{"$ref":"#/definitions/foo"}]}', '"a"');
-- empty tokens in $ref json-pointer
-- number is valid
SELECT is_jsonb_valid('{"definitions":{"":{"definitions":{"":{"type":"number"}}}},"allOf":[{"$ref":"#/definitions//definitions/"}]}', '1');
-- non-number is invalid
SELECT is_jsonb_valid('{"definitions":{"":{"definitions":{"":{"type":"number"}}}},"allOf":[{"$ref":"#/definitions//definitions/"}]}', '"a"');