-- maximum validation
-- below the maximum is valid
SELECT is_jsonb_valid_draft_v7('{"maximum":3}', '2.6');
-- boundary point is valid
SELECT is_jsonb_valid_draft_v7('{"maximum":3}', '3');
-- above the maximum is invalid
SELECT is_jsonb_valid_draft_v7('{"maximum":3}', '3.5');
-- ignores non-numbers
SELECT is_jsonb_valid_draft_v7('{"maximum":3}', '"x"');
-- maximum validation with unsigned integer
-- below the maximum is invalid
SELECT is_jsonb_valid_draft_v7('{"maximum":300}', '299.97');
-- boundary point integer is valid
SELECT is_jsonb_valid_draft_v7('{"maximum":300}', '300');
-- boundary point float is valid
SELECT is_jsonb_valid_draft_v7('{"maximum":300}', '300');
-- above the maximum is invalid
SELECT is_jsonb_valid_draft_v7('{"maximum":300}', '300.5');