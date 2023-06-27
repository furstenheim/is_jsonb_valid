-- oneOf
-- first oneOf valid
SELECT is_jsonb_valid_draft_v7('{"oneOf":[{"type":"integer"},{"minimum":2}]}', '1');
-- second oneOf valid
SELECT is_jsonb_valid_draft_v7('{"oneOf":[{"type":"integer"},{"minimum":2}]}', '2.5');
-- both oneOf valid
SELECT is_jsonb_valid_draft_v7('{"oneOf":[{"type":"integer"},{"minimum":2}]}', '3');
-- neither oneOf valid
SELECT is_jsonb_valid_draft_v7('{"oneOf":[{"type":"integer"},{"minimum":2}]}', '1.5');
-- oneOf with base schema
-- mismatch base schema
SELECT is_jsonb_valid_draft_v7('{"type":"string","oneOf":[{"minLength":2},{"maxLength":4}]}', '3');
-- one oneOf valid
SELECT is_jsonb_valid_draft_v7('{"type":"string","oneOf":[{"minLength":2},{"maxLength":4}]}', '"foobar"');
-- both oneOf valid
SELECT is_jsonb_valid_draft_v7('{"type":"string","oneOf":[{"minLength":2},{"maxLength":4}]}', '"foo"');
-- oneOf with boolean schemas, all true
-- any value is invalid
SELECT is_jsonb_valid_draft_v7('{"oneOf":[true,true,true]}', '"foo"');
-- oneOf with boolean schemas, one true
-- any value is valid
SELECT is_jsonb_valid_draft_v7('{"oneOf":[true,false,false]}', '"foo"');
-- oneOf with boolean schemas, more than one true
-- any value is invalid
SELECT is_jsonb_valid_draft_v7('{"oneOf":[true,true,false]}', '"foo"');
-- oneOf with boolean schemas, all false
-- any value is invalid
SELECT is_jsonb_valid_draft_v7('{"oneOf":[false,false,false]}', '"foo"');
-- oneOf complex types
-- first oneOf valid (complex)
SELECT is_jsonb_valid_draft_v7('{"oneOf":[{"properties":{"bar":{"type":"integer"}},"required":["bar"]},{"properties":{"foo":{"type":"string"}},"required":["foo"]}]}', '{"bar":2}');
-- second oneOf valid (complex)
SELECT is_jsonb_valid_draft_v7('{"oneOf":[{"properties":{"bar":{"type":"integer"}},"required":["bar"]},{"properties":{"foo":{"type":"string"}},"required":["foo"]}]}', '{"foo":"baz"}');
-- both oneOf valid (complex)
SELECT is_jsonb_valid_draft_v7('{"oneOf":[{"properties":{"bar":{"type":"integer"}},"required":["bar"]},{"properties":{"foo":{"type":"string"}},"required":["foo"]}]}', '{"foo":"baz","bar":2}');
-- neither oneOf valid (complex)
SELECT is_jsonb_valid_draft_v7('{"oneOf":[{"properties":{"bar":{"type":"integer"}},"required":["bar"]},{"properties":{"foo":{"type":"string"}},"required":["foo"]}]}', '{"foo":2,"bar":"quux"}');
-- oneOf with empty schema
-- one valid - valid
SELECT is_jsonb_valid_draft_v7('{"oneOf":[{"type":"number"},{}]}', '"foo"');
-- both valid - invalid
SELECT is_jsonb_valid_draft_v7('{"oneOf":[{"type":"number"},{}]}', '123');
-- oneOf with required
-- both invalid - invalid
SELECT is_jsonb_valid_draft_v7('{"type":"object","oneOf":[{"required":["foo","bar"]},{"required":["foo","baz"]}]}', '{"bar":2}');
-- first valid - valid
SELECT is_jsonb_valid_draft_v7('{"type":"object","oneOf":[{"required":["foo","bar"]},{"required":["foo","baz"]}]}', '{"foo":1,"bar":2}');
-- second valid - valid
SELECT is_jsonb_valid_draft_v7('{"type":"object","oneOf":[{"required":["foo","bar"]},{"required":["foo","baz"]}]}', '{"foo":1,"baz":3}');
-- both valid - invalid
SELECT is_jsonb_valid_draft_v7('{"type":"object","oneOf":[{"required":["foo","bar"]},{"required":["foo","baz"]}]}', '{"foo":1,"bar":2,"baz":3}');
-- oneOf with missing optional property
-- first oneOf valid
SELECT is_jsonb_valid_draft_v7('{"oneOf":[{"properties":{"bar":true,"baz":true},"required":["bar"]},{"properties":{"foo":true},"required":["foo"]}]}', '{"bar":8}');
-- second oneOf valid
SELECT is_jsonb_valid_draft_v7('{"oneOf":[{"properties":{"bar":true,"baz":true},"required":["bar"]},{"properties":{"foo":true},"required":["foo"]}]}', '{"foo":"foo"}');
-- both oneOf valid
SELECT is_jsonb_valid_draft_v7('{"oneOf":[{"properties":{"bar":true,"baz":true},"required":["bar"]},{"properties":{"foo":true},"required":["foo"]}]}', '{"foo":"foo","bar":8}');
-- neither oneOf valid
SELECT is_jsonb_valid_draft_v7('{"oneOf":[{"properties":{"bar":true,"baz":true},"required":["bar"]},{"properties":{"foo":true},"required":["foo"]}]}', '{"baz":"quux"}');
-- nested oneOf, to check validation semantics
-- null is valid
SELECT is_jsonb_valid_draft_v7('{"oneOf":[{"oneOf":[{"type":"null"}]}]}', 'null');
-- anything non-null is invalid
SELECT is_jsonb_valid_draft_v7('{"oneOf":[{"oneOf":[{"type":"null"}]}]}', '123');