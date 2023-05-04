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
-- $ref resolves to /definitions/base_foo, data does not validate
SELECT is_jsonb_valid_draft_v7('{"$id":"http://localhost:1234/sibling_id/base/","definitions":{"foo":{"$id":"http://localhost:1234/sibling_id/foo.json","type":"string"},"base_foo":{"$comment":"this canonical uri is http://localhost:1234/sibling_id/base/foo.json","$id":"foo.json","type":"number"}},"allOf":[{"$comment":"$ref resolves to http://localhost:1234/sibling_id/base/foo.json, not http://localhost:1234/sibling_id/foo.json","$id":"http://localhost:1234/sibling_id/","$ref":"foo.json"}]}', '"a"');
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
-- refs with relative uris and defs
-- invalid on inner field
SELECT is_jsonb_valid_draft_v7('{"$id":"http://example.com/schema-relative-uri-defs1.json","properties":{"foo":{"$id":"schema-relative-uri-defs2.json","definitions":{"inner":{"properties":{"bar":{"type":"string"}}}},"allOf":[{"$ref":"#/definitions/inner"}]}},"allOf":[{"$ref":"schema-relative-uri-defs2.json"}]}', '{"foo":{"bar":1},"bar":"a"}');
-- invalid on outer field
SELECT is_jsonb_valid_draft_v7('{"$id":"http://example.com/schema-relative-uri-defs1.json","properties":{"foo":{"$id":"schema-relative-uri-defs2.json","definitions":{"inner":{"properties":{"bar":{"type":"string"}}}},"allOf":[{"$ref":"#/definitions/inner"}]}},"allOf":[{"$ref":"schema-relative-uri-defs2.json"}]}', '{"foo":{"bar":"a"},"bar":1}');
-- valid on both fields
SELECT is_jsonb_valid_draft_v7('{"$id":"http://example.com/schema-relative-uri-defs1.json","properties":{"foo":{"$id":"schema-relative-uri-defs2.json","definitions":{"inner":{"properties":{"bar":{"type":"string"}}}},"allOf":[{"$ref":"#/definitions/inner"}]}},"allOf":[{"$ref":"schema-relative-uri-defs2.json"}]}', '{"foo":{"bar":"a"},"bar":"a"}');
-- relative refs with absolute uris and defs
-- invalid on inner field
SELECT is_jsonb_valid_draft_v7('{"$id":"http://example.com/schema-refs-absolute-uris-defs1.json","properties":{"foo":{"$id":"http://example.com/schema-refs-absolute-uris-defs2.json","definitions":{"inner":{"properties":{"bar":{"type":"string"}}}},"allOf":[{"$ref":"#/definitions/inner"}]}},"allOf":[{"$ref":"schema-refs-absolute-uris-defs2.json"}]}', '{"foo":{"bar":1},"bar":"a"}');
-- invalid on outer field
SELECT is_jsonb_valid_draft_v7('{"$id":"http://example.com/schema-refs-absolute-uris-defs1.json","properties":{"foo":{"$id":"http://example.com/schema-refs-absolute-uris-defs2.json","definitions":{"inner":{"properties":{"bar":{"type":"string"}}}},"allOf":[{"$ref":"#/definitions/inner"}]}},"allOf":[{"$ref":"schema-refs-absolute-uris-defs2.json"}]}', '{"foo":{"bar":"a"},"bar":1}');
-- valid on both fields
SELECT is_jsonb_valid_draft_v7('{"$id":"http://example.com/schema-refs-absolute-uris-defs1.json","properties":{"foo":{"$id":"http://example.com/schema-refs-absolute-uris-defs2.json","definitions":{"inner":{"properties":{"bar":{"type":"string"}}}},"allOf":[{"$ref":"#/definitions/inner"}]}},"allOf":[{"$ref":"schema-refs-absolute-uris-defs2.json"}]}', '{"foo":{"bar":"a"},"bar":"a"}');
-- simple URN base URI with $ref via the URN
-- valid under the URN IDed schema
SELECT is_jsonb_valid_draft_v7('{"$comment":"URIs do not have to have HTTP(s) schemes","$id":"urn:uuid:deadbeef-1234-ffff-ffff-4321feebdaed","minimum":30,"properties":{"foo":{"$ref":"urn:uuid:deadbeef-1234-ffff-ffff-4321feebdaed"}}}', '{"foo":37}');
-- invalid under the URN IDed schema
SELECT is_jsonb_valid_draft_v7('{"$comment":"URIs do not have to have HTTP(s) schemes","$id":"urn:uuid:deadbeef-1234-ffff-ffff-4321feebdaed","minimum":30,"properties":{"foo":{"$ref":"urn:uuid:deadbeef-1234-ffff-ffff-4321feebdaed"}}}', '{"foo":12}');
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
-- URN base URI with URN and JSON pointer ref
-- a string is valid
SELECT is_jsonb_valid_draft_v7('{"$id":"urn:uuid:deadbeef-1234-0000-0000-4321feebdaed","properties":{"foo":{"$ref":"urn:uuid:deadbeef-1234-0000-0000-4321feebdaed#/definitions/bar"}},"definitions":{"bar":{"type":"string"}}}', '{"foo":"bar"}');
-- a non-string is invalid
SELECT is_jsonb_valid_draft_v7('{"$id":"urn:uuid:deadbeef-1234-0000-0000-4321feebdaed","properties":{"foo":{"$ref":"urn:uuid:deadbeef-1234-0000-0000-4321feebdaed#/definitions/bar"}},"definitions":{"bar":{"type":"string"}}}', '{"foo":12}');
-- URN base URI with URN and anchor ref
-- a string is valid
SELECT is_jsonb_valid_draft_v7('{"$id":"urn:uuid:deadbeef-1234-ff00-00ff-4321feebdaed","properties":{"foo":{"$ref":"urn:uuid:deadbeef-1234-ff00-00ff-4321feebdaed#something"}},"definitions":{"bar":{"$id":"#something","type":"string"}}}', '{"foo":"bar"}');
-- a non-string is invalid
SELECT is_jsonb_valid_draft_v7('{"$id":"urn:uuid:deadbeef-1234-ff00-00ff-4321feebdaed","properties":{"foo":{"$ref":"urn:uuid:deadbeef-1234-ff00-00ff-4321feebdaed#something"}},"definitions":{"bar":{"$id":"#something","type":"string"}}}', '{"foo":12}');
-- ref to if
-- a non-integer is invalid due to the $ref
SELECT is_jsonb_valid_draft_v7('{"allOf":[{"$ref":"http://example.com/ref/if"},{"if":{"$id":"http://example.com/ref/if","type":"integer"}}]}', '"foo"');
-- an integer is valid
SELECT is_jsonb_valid_draft_v7('{"allOf":[{"$ref":"http://example.com/ref/if"},{"if":{"$id":"http://example.com/ref/if","type":"integer"}}]}', '12');
-- ref to then
-- a non-integer is invalid due to the $ref
SELECT is_jsonb_valid_draft_v7('{"allOf":[{"$ref":"http://example.com/ref/then"},{"then":{"$id":"http://example.com/ref/then","type":"integer"}}]}', '"foo"');
-- an integer is valid
SELECT is_jsonb_valid_draft_v7('{"allOf":[{"$ref":"http://example.com/ref/then"},{"then":{"$id":"http://example.com/ref/then","type":"integer"}}]}', '12');
-- ref to else
-- a non-integer is invalid due to the $ref
SELECT is_jsonb_valid_draft_v7('{"allOf":[{"$ref":"http://example.com/ref/else"},{"else":{"$id":"http://example.com/ref/else","type":"integer"}}]}', '"foo"');
-- an integer is valid
SELECT is_jsonb_valid_draft_v7('{"allOf":[{"$ref":"http://example.com/ref/else"},{"else":{"$id":"http://example.com/ref/else","type":"integer"}}]}', '12');
-- ref with absolute-path-reference
-- a string is valid
SELECT is_jsonb_valid_draft_v7('{"$id":"http://example.com/ref/absref.json","definitions":{"a":{"$id":"http://example.com/ref/absref/foobar.json","type":"number"},"b":{"$id":"http://example.com/absref/foobar.json","type":"string"}},"allOf":[{"$ref":"/absref/foobar.json"}]}', '"foo"');
-- an integer is invalid
SELECT is_jsonb_valid_draft_v7('{"$id":"http://example.com/ref/absref.json","definitions":{"a":{"$id":"http://example.com/ref/absref/foobar.json","type":"number"},"b":{"$id":"http://example.com/absref/foobar.json","type":"string"}},"allOf":[{"$ref":"/absref/foobar.json"}]}', '12');
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