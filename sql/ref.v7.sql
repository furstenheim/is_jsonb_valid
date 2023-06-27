-- root pointer ref
-- match
SELECT is_jsonb_valid_draft_v7('{"properties":{"foo":{"$ref":"#"}},"additionalProperties":false}', '{"foo":false}');
-- recursive match
SELECT is_jsonb_valid_draft_v7('{"properties":{"foo":{"$ref":"#"}},"additionalProperties":false}', '{"foo":{"foo":false}}');
-- mismatch
SELECT is_jsonb_valid_draft_v7('{"properties":{"foo":{"$ref":"#"}},"additionalProperties":false}', '{"bar":false}');
-- recursive mismatch
SELECT is_jsonb_valid_draft_v7('{"properties":{"foo":{"$ref":"#"}},"additionalProperties":false}', '{"foo":{"bar":false}}');
-- relative pointer ref to object
-- match
SELECT is_jsonb_valid_draft_v7('{"properties":{"foo":{"type":"integer"},"bar":{"$ref":"#/properties/foo"}}}', '{"bar":3}');
-- mismatch
SELECT is_jsonb_valid_draft_v7('{"properties":{"foo":{"type":"integer"},"bar":{"$ref":"#/properties/foo"}}}', '{"bar":true}');
-- relative pointer ref to array
-- match array
SELECT is_jsonb_valid_draft_v7('{"items":[{"type":"integer"},{"$ref":"#/items/0"}]}', '[1,2]');
-- mismatch array
SELECT is_jsonb_valid_draft_v7('{"items":[{"type":"integer"},{"$ref":"#/items/0"}]}', '[1,"foo"]');
-- nested refs
-- nested ref valid
SELECT is_jsonb_valid_draft_v7('{"definitions":{"a":{"type":"integer"},"b":{"$ref":"#/definitions/a"},"c":{"$ref":"#/definitions/b"}},"allOf":[{"$ref":"#/definitions/c"}]}', '5');
-- nested ref invalid
SELECT is_jsonb_valid_draft_v7('{"definitions":{"a":{"type":"integer"},"b":{"$ref":"#/definitions/a"},"c":{"$ref":"#/definitions/b"}},"allOf":[{"$ref":"#/definitions/c"}]}', '"a"');
-- ref overrides any sibling keywords
-- ref valid
SELECT is_jsonb_valid_draft_v7('{"definitions":{"reffed":{"type":"array"}},"properties":{"foo":{"$ref":"#/definitions/reffed","maxItems":2}}}', '{"foo":[]}');
-- ref valid, maxItems ignored
SELECT is_jsonb_valid_draft_v7('{"definitions":{"reffed":{"type":"array"}},"properties":{"foo":{"$ref":"#/definitions/reffed","maxItems":2}}}', '{"foo":[1,2,3]}');
-- ref invalid
SELECT is_jsonb_valid_draft_v7('{"definitions":{"reffed":{"type":"array"}},"properties":{"foo":{"$ref":"#/definitions/reffed","maxItems":2}}}', '{"foo":"string"}');
-- $ref prevents a sibling $id from changing the base uri
-- property named $ref that is not a reference
-- property named $ref valid
SELECT is_jsonb_valid_draft_v7('{"properties":{"$ref":{"type":"string"}}}', '{"$ref":"a"}');
-- property named $ref invalid
SELECT is_jsonb_valid_draft_v7('{"properties":{"$ref":{"type":"string"}}}', '{"$ref":2}');
-- property named $ref, containing an actual $ref
-- property named $ref valid
SELECT is_jsonb_valid_draft_v7('{"properties":{"$ref":{"$ref":"#/definitions/is-string"}},"definitions":{"is-string":{"type":"string"}}}', '{"$ref":"a"}');
-- property named $ref invalid
SELECT is_jsonb_valid_draft_v7('{"properties":{"$ref":{"$ref":"#/definitions/is-string"}},"definitions":{"is-string":{"type":"string"}}}', '{"$ref":2}');
-- $ref to boolean schema true
-- any value is valid
SELECT is_jsonb_valid_draft_v7('{"allOf":[{"$ref":"#/definitions/bool"}],"definitions":{"bool":true}}', '"foo"');
-- $ref to boolean schema false
-- any value is invalid
SELECT is_jsonb_valid_draft_v7('{"allOf":[{"$ref":"#/definitions/bool"}],"definitions":{"bool":false}}', '"foo"');
-- naive replacement of $ref with its destination is not correct
-- do not evaluate the $ref inside the enum, matching any string
SELECT is_jsonb_valid_draft_v7('{"definitions":{"a_string":{"type":"string"}},"enum":[{"$ref":"#/definitions/a_string"}]}', '"this is a string"');
-- do not evaluate the $ref inside the enum, definition exact match
SELECT is_jsonb_valid_draft_v7('{"definitions":{"a_string":{"type":"string"}},"enum":[{"$ref":"#/definitions/a_string"}]}', '{"type":"string"}');
-- match the enum exactly
SELECT is_jsonb_valid_draft_v7('{"definitions":{"a_string":{"type":"string"}},"enum":[{"$ref":"#/definitions/a_string"}]}', '{"$ref":"#/definitions/a_string"}');
-- simple URN base URI with JSON pointer
-- a string is valid
SELECT is_jsonb_valid_draft_v7('{"$comment":"URIs do not have to have HTTP(s) schemes","$id":"urn:uuid:deadbeef-1234-00ff-ff00-4321feebdaed","properties":{"foo":{"$ref":"#/definitions/bar"}},"definitions":{"bar":{"type":"string"}}}', '{"foo":"bar"}');
-- a non-string is invalid
SELECT is_jsonb_valid_draft_v7('{"$comment":"URIs do not have to have HTTP(s) schemes","$id":"urn:uuid:deadbeef-1234-00ff-ff00-4321feebdaed","properties":{"foo":{"$ref":"#/definitions/bar"}},"definitions":{"bar":{"type":"string"}}}', '{"foo":12}');
-- URN base URI with NSS
-- a string is valid
SELECT is_jsonb_valid_draft_v7('{"$comment":"RFC 8141 §2.2","$id":"urn:example:1/406/47452/2","properties":{"foo":{"$ref":"#/definitions/bar"}},"definitions":{"bar":{"type":"string"}}}', '{"foo":"bar"}');
-- a non-string is invalid
SELECT is_jsonb_valid_draft_v7('{"$comment":"RFC 8141 §2.2","$id":"urn:example:1/406/47452/2","properties":{"foo":{"$ref":"#/definitions/bar"}},"definitions":{"bar":{"type":"string"}}}', '{"foo":12}');
-- URN base URI with r-component
-- a string is valid
SELECT is_jsonb_valid_draft_v7('{"$comment":"RFC 8141 §2.3.1","$id":"urn:example:foo-bar-baz-qux?+CCResolve:cc=uk","properties":{"foo":{"$ref":"#/definitions/bar"}},"definitions":{"bar":{"type":"string"}}}', '{"foo":"bar"}');
-- a non-string is invalid
SELECT is_jsonb_valid_draft_v7('{"$comment":"RFC 8141 §2.3.1","$id":"urn:example:foo-bar-baz-qux?+CCResolve:cc=uk","properties":{"foo":{"$ref":"#/definitions/bar"}},"definitions":{"bar":{"type":"string"}}}', '{"foo":12}');
-- URN base URI with q-component
-- a string is valid
SELECT is_jsonb_valid_draft_v7('{"$comment":"RFC 8141 §2.3.2","$id":"urn:example:weather?=op=map&lat=39.56&lon=-104.85&datetime=1969-07-21T02:56:15Z","properties":{"foo":{"$ref":"#/definitions/bar"}},"definitions":{"bar":{"type":"string"}}}', '{"foo":"bar"}');
-- a non-string is invalid
SELECT is_jsonb_valid_draft_v7('{"$comment":"RFC 8141 §2.3.2","$id":"urn:example:weather?=op=map&lat=39.56&lon=-104.85&datetime=1969-07-21T02:56:15Z","properties":{"foo":{"$ref":"#/definitions/bar"}},"definitions":{"bar":{"type":"string"}}}', '{"foo":12}');
-- $id with file URI still resolves pointers - *nix
-- number is valid
SELECT is_jsonb_valid_draft_v7('{"$id":"file:///folder/file.json","definitions":{"foo":{"type":"number"}},"allOf":[{"$ref":"#/definitions/foo"}]}', '1');
-- non-number is invalid
SELECT is_jsonb_valid_draft_v7('{"$id":"file:///folder/file.json","definitions":{"foo":{"type":"number"}},"allOf":[{"$ref":"#/definitions/foo"}]}', '"a"');
-- $id with file URI still resolves pointers - windows
-- number is valid
SELECT is_jsonb_valid_draft_v7('{"$id":"file:///c:/folder/file.json","definitions":{"foo":{"type":"number"}},"allOf":[{"$ref":"#/definitions/foo"}]}', '1');
-- non-number is invalid
SELECT is_jsonb_valid_draft_v7('{"$id":"file:///c:/folder/file.json","definitions":{"foo":{"type":"number"}},"allOf":[{"$ref":"#/definitions/foo"}]}', '"a"');
-- empty tokens in $ref json-pointer
-- number is valid
SELECT is_jsonb_valid_draft_v7('{"definitions":{"":{"definitions":{"":{"type":"number"}}}},"allOf":[{"$ref":"#/definitions//definitions/"}]}', '1');
-- non-number is invalid
SELECT is_jsonb_valid_draft_v7('{"definitions":{"":{"definitions":{"":{"type":"number"}}}},"allOf":[{"$ref":"#/definitions//definitions/"}]}', '"a"');