-- minimum validation
-- above the minimum is valid
SELECT is_jsonb_valid_draft_v7('{"minimum":1.1}', '2.6');
-- boundary point is valid
SELECT is_jsonb_valid_draft_v7('{"minimum":1.1}', '1.1');
-- below the minimum is invalid
SELECT is_jsonb_valid_draft_v7('{"minimum":1.1}', '0.6');
-- ignores non-numbers
SELECT is_jsonb_valid_draft_v7('{"minimum":1.1}', '"x"');
-- minimum validation with signed integer
-- negative above the minimum is valid
SELECT is_jsonb_valid_draft_v7('{"minimum":-2}', '-1');
-- positive above the minimum is valid
SELECT is_jsonb_valid_draft_v7('{"minimum":-2}', '0');
-- boundary point is valid
SELECT is_jsonb_valid_draft_v7('{"minimum":-2}', '-2');
-- boundary point with float is valid
SELECT is_jsonb_valid_draft_v7('{"minimum":-2}', '-2');
-- float below the minimum is invalid
SELECT is_jsonb_valid_draft_v7('{"minimum":-2}', '-2.0001');
-- int below the minimum is invalid
SELECT is_jsonb_valid_draft_v7('{"minimum":-2}', '-3');
-- ignores non-numbers
SELECT is_jsonb_valid_draft_v7('{"minimum":-2}', '"x"');