-- anyOf
-- first anyOf valid
SELECT is_jsonb_valid_draft_v7('{"anyOf":[{"type":"integer"},{"minimum":2}]}', '1');
-- second anyOf valid
SELECT is_jsonb_valid_draft_v7('{"anyOf":[{"type":"integer"},{"minimum":2}]}', '2.5');
-- both anyOf valid
SELECT is_jsonb_valid_draft_v7('{"anyOf":[{"type":"integer"},{"minimum":2}]}', '3');
-- neither anyOf valid
SELECT is_jsonb_valid_draft_v7('{"anyOf":[{"type":"integer"},{"minimum":2}]}', '1.5');
-- anyOf with base schema
-- mismatch base schema
SELECT is_jsonb_valid_draft_v7('{"type":"string","anyOf":[{"maxLength":2},{"minLength":4}]}', '3');
-- one anyOf valid
SELECT is_jsonb_valid_draft_v7('{"type":"string","anyOf":[{"maxLength":2},{"minLength":4}]}', '"foobar"');
-- both anyOf invalid
SELECT is_jsonb_valid_draft_v7('{"type":"string","anyOf":[{"maxLength":2},{"minLength":4}]}', '"foo"');
-- anyOf with boolean schemas, all true
-- any value is valid
SELECT is_jsonb_valid_draft_v7('{"anyOf":[true,true]}', '"foo"');
-- anyOf with boolean schemas, some true
-- any value is valid
SELECT is_jsonb_valid_draft_v7('{"anyOf":[true,false]}', '"foo"');
-- anyOf with boolean schemas, all false
-- any value is invalid
SELECT is_jsonb_valid_draft_v7('{"anyOf":[false,false]}', '"foo"');
-- anyOf complex types
-- first anyOf valid (complex)
SELECT is_jsonb_valid_draft_v7('{"anyOf":[{"properties":{"bar":{"type":"integer"}},"required":["bar"]},{"properties":{"foo":{"type":"string"}},"required":["foo"]}]}', '{"bar":2}');
-- second anyOf valid (complex)
SELECT is_jsonb_valid_draft_v7('{"anyOf":[{"properties":{"bar":{"type":"integer"}},"required":["bar"]},{"properties":{"foo":{"type":"string"}},"required":["foo"]}]}', '{"foo":"baz"}');
-- both anyOf valid (complex)
SELECT is_jsonb_valid_draft_v7('{"anyOf":[{"properties":{"bar":{"type":"integer"}},"required":["bar"]},{"properties":{"foo":{"type":"string"}},"required":["foo"]}]}', '{"foo":"baz","bar":2}');
-- neither anyOf valid (complex)
SELECT is_jsonb_valid_draft_v7('{"anyOf":[{"properties":{"bar":{"type":"integer"}},"required":["bar"]},{"properties":{"foo":{"type":"string"}},"required":["foo"]}]}', '{"foo":2,"bar":"quux"}');
-- anyOf with one empty schema
-- string is valid
SELECT is_jsonb_valid_draft_v7('{"anyOf":[{"type":"number"},{}]}', '"foo"');
-- number is valid
SELECT is_jsonb_valid_draft_v7('{"anyOf":[{"type":"number"},{}]}', '123');
-- nested anyOf, to check validation semantics
-- null is valid
SELECT is_jsonb_valid_draft_v7('{"anyOf":[{"anyOf":[{"type":"null"}]}]}', 'null');
-- anything non-null is invalid
SELECT is_jsonb_valid_draft_v7('{"anyOf":[{"anyOf":[{"type":"null"}]}]}', '123');