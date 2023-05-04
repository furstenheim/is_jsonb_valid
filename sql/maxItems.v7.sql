-- maxItems validation
-- shorter is valid
SELECT is_jsonb_valid_draft_v7('{"maxItems":2}', '[1]');
-- exact length is valid
SELECT is_jsonb_valid_draft_v7('{"maxItems":2}', '[1,2]');
-- too long is invalid
SELECT is_jsonb_valid_draft_v7('{"maxItems":2}', '[1,2,3]');
-- ignores non-arrays
SELECT is_jsonb_valid_draft_v7('{"maxItems":2}', '"foobar"');
-- maxItems validation with a decimal
-- shorter is valid
SELECT is_jsonb_valid_draft_v7('{"maxItems":2}', '[1]');
-- too long is invalid
SELECT is_jsonb_valid_draft_v7('{"maxItems":2}', '[1,2,3]');