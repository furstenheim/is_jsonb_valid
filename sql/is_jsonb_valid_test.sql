CREATE EXTENSION is_jsonb_valid;
SELECT is_jsonb_valid('{}', '{}');
SELECT is_jsonb_valid('{"type": "object"}', '{}');
SELECT is_jsonb_valid('{"type": "object"}', '2');