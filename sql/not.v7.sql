-- not
-- allowed
SELECT is_jsonb_valid_draft_v7('{"not":{"type":"integer"}}', '"foo"');
-- disallowed
SELECT is_jsonb_valid_draft_v7('{"not":{"type":"integer"}}', '1');
-- not multiple types
-- valid
SELECT is_jsonb_valid_draft_v7('{"not":{"type":["integer","boolean"]}}', '"foo"');
-- mismatch
SELECT is_jsonb_valid_draft_v7('{"not":{"type":["integer","boolean"]}}', '1');
-- other mismatch
SELECT is_jsonb_valid_draft_v7('{"not":{"type":["integer","boolean"]}}', 'true');
-- not more complex schema
-- match
SELECT is_jsonb_valid_draft_v7('{"not":{"type":"object","properties":{"foo":{"type":"string"}}}}', '1');
-- other match
SELECT is_jsonb_valid_draft_v7('{"not":{"type":"object","properties":{"foo":{"type":"string"}}}}', '{"foo":1}');
-- mismatch
SELECT is_jsonb_valid_draft_v7('{"not":{"type":"object","properties":{"foo":{"type":"string"}}}}', '{"foo":"bar"}');
-- forbidden property
-- property present
SELECT is_jsonb_valid_draft_v7('{"properties":{"foo":{"not":{}}}}', '{"foo":1,"bar":2}');
-- property absent
SELECT is_jsonb_valid_draft_v7('{"properties":{"foo":{"not":{}}}}', '{"bar":1,"baz":2}');
-- not with boolean schema true
-- any value is invalid
SELECT is_jsonb_valid_draft_v7('{"not":true}', '"foo"');
-- not with boolean schema false
-- any value is valid
SELECT is_jsonb_valid_draft_v7('{"not":false}', '"foo"');