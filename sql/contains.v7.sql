-- contains keyword validation
-- array with item matching schema (5) is valid
SELECT is_jsonb_valid_draft_v7('{"contains":{"minimum":5}}', '[3,4,5]');
-- array with item matching schema (6) is valid
SELECT is_jsonb_valid_draft_v7('{"contains":{"minimum":5}}', '[3,4,6]');
-- array with two items matching schema (5, 6) is valid
SELECT is_jsonb_valid_draft_v7('{"contains":{"minimum":5}}', '[3,4,5,6]');
-- array without items matching schema is invalid
SELECT is_jsonb_valid_draft_v7('{"contains":{"minimum":5}}', '[2,3,4]');
-- empty array is invalid
SELECT is_jsonb_valid_draft_v7('{"contains":{"minimum":5}}', '[]');
-- not array is valid
SELECT is_jsonb_valid_draft_v7('{"contains":{"minimum":5}}', '{}');
-- contains keyword with const keyword
-- array with item 5 is valid
SELECT is_jsonb_valid_draft_v7('{"contains":{"const":5}}', '[3,4,5]');
-- array with two items 5 is valid
SELECT is_jsonb_valid_draft_v7('{"contains":{"const":5}}', '[3,4,5,5]');
-- array without item 5 is invalid
SELECT is_jsonb_valid_draft_v7('{"contains":{"const":5}}', '[1,2,3,4]');
-- contains keyword with boolean schema true
-- any non-empty array is valid
SELECT is_jsonb_valid_draft_v7('{"contains":true}', '["foo"]');
-- empty array is invalid
SELECT is_jsonb_valid_draft_v7('{"contains":true}', '[]');
-- contains keyword with boolean schema false
-- any non-empty array is invalid
SELECT is_jsonb_valid_draft_v7('{"contains":false}', '["foo"]');
-- empty array is invalid
SELECT is_jsonb_valid_draft_v7('{"contains":false}', '[]');
-- non-arrays are valid
SELECT is_jsonb_valid_draft_v7('{"contains":false}', '"contains does not apply to strings"');
-- items + contains
-- matches items, does not match contains
SELECT is_jsonb_valid_draft_v7('{"items":{"multipleOf":2},"contains":{"multipleOf":3}}', '[2,4,8]');
-- does not match items, matches contains
SELECT is_jsonb_valid_draft_v7('{"items":{"multipleOf":2},"contains":{"multipleOf":3}}', '[3,6,9]');
-- matches both items and contains
SELECT is_jsonb_valid_draft_v7('{"items":{"multipleOf":2},"contains":{"multipleOf":3}}', '[6,12]');
-- matches neither items nor contains
SELECT is_jsonb_valid_draft_v7('{"items":{"multipleOf":2},"contains":{"multipleOf":3}}', '[1,5]');
-- contains with false if subschema
-- any non-empty array is valid
SELECT is_jsonb_valid_draft_v7('{"contains":{"if":false,"else":true}}', '["foo"]');
-- empty array is invalid
SELECT is_jsonb_valid_draft_v7('{"contains":{"if":false,"else":true}}', '[]');
-- contains with null instance elements
-- allows null items
SELECT is_jsonb_valid_draft_v7('{"contains":{"type":"null"}}', '[null]');