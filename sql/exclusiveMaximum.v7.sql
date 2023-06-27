-- exclusiveMaximum validation
-- below the exclusiveMaximum is valid
SELECT is_jsonb_valid_draft_v7('{"exclusiveMaximum":3}', '2.2');
-- boundary point is invalid
SELECT is_jsonb_valid_draft_v7('{"exclusiveMaximum":3}', '3');
-- above the exclusiveMaximum is invalid
SELECT is_jsonb_valid_draft_v7('{"exclusiveMaximum":3}', '3.5');
-- ignores non-numbers
SELECT is_jsonb_valid_draft_v7('{"exclusiveMaximum":3}', '"x"');