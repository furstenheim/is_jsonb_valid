-- minItems validation
-- longer is valid
SELECT is_jsonb_valid_draft_v7('{"minItems":1}', '[1,2]');
-- exact length is valid
SELECT is_jsonb_valid_draft_v7('{"minItems":1}', '[1]');
-- too short is invalid
SELECT is_jsonb_valid_draft_v7('{"minItems":1}', '[]');
-- ignores non-arrays
SELECT is_jsonb_valid_draft_v7('{"minItems":1}', '""');
-- minItems validation with a decimal
-- longer is valid
SELECT is_jsonb_valid_draft_v7('{"minItems":1}', '[1,2]');
-- too short is invalid
SELECT is_jsonb_valid_draft_v7('{"minItems":1}', '[]');