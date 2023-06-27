-- minProperties validation
-- longer is valid
SELECT is_jsonb_valid_draft_v7('{"minProperties":1}', '{"foo":1,"bar":2}');
-- exact length is valid
SELECT is_jsonb_valid_draft_v7('{"minProperties":1}', '{"foo":1}');
-- too short is invalid
SELECT is_jsonb_valid_draft_v7('{"minProperties":1}', '{}');
-- ignores arrays
SELECT is_jsonb_valid_draft_v7('{"minProperties":1}', '[]');
-- ignores strings
SELECT is_jsonb_valid_draft_v7('{"minProperties":1}', '""');
-- ignores other non-objects
SELECT is_jsonb_valid_draft_v7('{"minProperties":1}', '12');
-- minProperties validation with a decimal
-- longer is valid
SELECT is_jsonb_valid_draft_v7('{"minProperties":1}', '{"foo":1,"bar":2}');
-- too short is invalid
SELECT is_jsonb_valid_draft_v7('{"minProperties":1}', '{}');