CREATE EXTENSION is_jsonb_valid;
SELECT is_jsonb_valid('{}', '{}');
SELECT is_jsonb_valid('{"type": "object"}', '{}');
SELECT is_jsonb_valid('{"type": "object"}', '2');
SELECT is_jsonb_valid('{"type": "object"}', '{"a": 1}');
SELECT is_jsonb_valid('{"type": "number"}', '2');
SELECT is_jsonb_valid('{"type": "integer"}', '2');
SELECT is_jsonb_valid('{"type": "integer"}', '2.5');
SELECT is_jsonb_valid('{"type": 1}', '2');