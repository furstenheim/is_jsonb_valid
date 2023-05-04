-- minLength validation
-- longer is valid
SELECT is_jsonb_valid_draft_v7('{"minLength":2}', '"foo"');
-- exact length is valid
SELECT is_jsonb_valid_draft_v7('{"minLength":2}', '"fo"');
-- too short is invalid
SELECT is_jsonb_valid_draft_v7('{"minLength":2}', '"f"');
-- ignores non-strings
SELECT is_jsonb_valid_draft_v7('{"minLength":2}', '1');
-- one supplementary Unicode code point is not long enough
SELECT is_jsonb_valid_draft_v7('{"minLength":2}', '"💩"');
-- minLength validation with a decimal
-- longer is valid
SELECT is_jsonb_valid_draft_v7('{"minLength":2}', '"foo"');
-- too short is invalid
SELECT is_jsonb_valid_draft_v7('{"minLength":2}', '"f"');