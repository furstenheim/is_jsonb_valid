-- exclusiveMinimum validation
-- above the exclusiveMinimum is valid
SELECT is_jsonb_valid_draft_v7('{"exclusiveMinimum":1.1}', '1.2');
-- boundary point is invalid
SELECT is_jsonb_valid_draft_v7('{"exclusiveMinimum":1.1}', '1.1');
-- below the exclusiveMinimum is invalid
SELECT is_jsonb_valid_draft_v7('{"exclusiveMinimum":1.1}', '0.6');
-- ignores non-numbers
SELECT is_jsonb_valid_draft_v7('{"exclusiveMinimum":1.1}', '"x"');