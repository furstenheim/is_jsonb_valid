-- maxProperties validation
-- shorter is valid
SELECT is_jsonb_valid_draft_v7('{"maxProperties":2}', '{"foo":1}');
-- exact length is valid
SELECT is_jsonb_valid_draft_v7('{"maxProperties":2}', '{"foo":1,"bar":2}');
-- too long is invalid
SELECT is_jsonb_valid_draft_v7('{"maxProperties":2}', '{"foo":1,"bar":2,"baz":3}');
-- ignores arrays
SELECT is_jsonb_valid_draft_v7('{"maxProperties":2}', '[1,2,3]');
-- ignores strings
SELECT is_jsonb_valid_draft_v7('{"maxProperties":2}', '"foobar"');
-- ignores other non-objects
SELECT is_jsonb_valid_draft_v7('{"maxProperties":2}', '12');
-- maxProperties validation with a decimal
-- shorter is valid
SELECT is_jsonb_valid_draft_v7('{"maxProperties":2}', '{"foo":1}');
-- too long is invalid
SELECT is_jsonb_valid_draft_v7('{"maxProperties":2}', '{"foo":1,"bar":2,"baz":3}');
-- maxProperties = 0 means the object is empty
-- no properties is valid
SELECT is_jsonb_valid_draft_v7('{"maxProperties":0}', '{}');
-- one property is invalid
SELECT is_jsonb_valid_draft_v7('{"maxProperties":0}', '{"foo":1}');