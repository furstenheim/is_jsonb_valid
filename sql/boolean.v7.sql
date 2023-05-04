-- boolean schema 'true'
-- number is valid
SELECT is_jsonb_valid_draft_v7('true', '1');
-- string is valid
SELECT is_jsonb_valid_draft_v7('true', '"foo"');
-- boolean true is valid
SELECT is_jsonb_valid_draft_v7('true', 'true');
-- boolean false is valid
SELECT is_jsonb_valid_draft_v7('true', 'false');
-- null is valid
SELECT is_jsonb_valid_draft_v7('true', 'null');
-- object is valid
SELECT is_jsonb_valid_draft_v7('true', '{"foo":"bar"}');
-- empty object is valid
SELECT is_jsonb_valid_draft_v7('true', '{}');
-- array is valid
SELECT is_jsonb_valid_draft_v7('true', '["foo"]');
-- empty array is valid
SELECT is_jsonb_valid_draft_v7('true', '[]');
-- boolean schema 'false'
-- number is invalid
SELECT is_jsonb_valid_draft_v7('false', '1');
-- string is invalid
SELECT is_jsonb_valid_draft_v7('false', '"foo"');
-- boolean true is invalid
SELECT is_jsonb_valid_draft_v7('false', 'true');
-- boolean false is invalid
SELECT is_jsonb_valid_draft_v7('false', 'false');
-- null is invalid
SELECT is_jsonb_valid_draft_v7('false', 'null');
-- object is invalid
SELECT is_jsonb_valid_draft_v7('false', '{"foo":"bar"}');
-- empty object is invalid
SELECT is_jsonb_valid_draft_v7('false', '{}');
-- array is invalid
SELECT is_jsonb_valid_draft_v7('false', '["foo"]');
-- empty array is invalid
SELECT is_jsonb_valid_draft_v7('false', '[]');