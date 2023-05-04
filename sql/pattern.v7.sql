-- pattern validation
-- a matching pattern is valid
SELECT is_jsonb_valid_draft_v7('{"pattern":"^a*$"}', '"aaa"');
-- a non-matching pattern is invalid
SELECT is_jsonb_valid_draft_v7('{"pattern":"^a*$"}', '"abc"');
-- ignores booleans
SELECT is_jsonb_valid_draft_v7('{"pattern":"^a*$"}', 'true');
-- ignores integers
SELECT is_jsonb_valid_draft_v7('{"pattern":"^a*$"}', '123');
-- ignores floats
SELECT is_jsonb_valid_draft_v7('{"pattern":"^a*$"}', '1');
-- ignores objects
SELECT is_jsonb_valid_draft_v7('{"pattern":"^a*$"}', '{}');
-- ignores arrays
SELECT is_jsonb_valid_draft_v7('{"pattern":"^a*$"}', '[]');
-- ignores null
SELECT is_jsonb_valid_draft_v7('{"pattern":"^a*$"}', 'null');
-- pattern is not anchored
-- matches a substring
SELECT is_jsonb_valid_draft_v7('{"pattern":"a+"}', '"xxaayy"');