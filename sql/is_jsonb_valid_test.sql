CREATE EXTENSION is_jsonb_valid;
SELECT is_jsonb_valid('{}', '{}');
SELECT is_jsonb_valid('{"type": "object"}', '{}');
SELECT is_jsonb_valid('{"type": "object"}', '2');
SELECT is_jsonb_valid('{"type": "object"}', '{"a": 1}');
SELECT is_jsonb_valid('{"type": "number"}', '2');
SELECT is_jsonb_valid('{"type": "integer"}', '2');
SELECT is_jsonb_valid('{"type": "integer"}', '2.5');
SELECT is_jsonb_valid('{"properties": {}}', '2.5');
SELECT is_jsonb_valid('{"properties": {"a": {"type": "null"}}}', '{"a": 1}');
SELECT is_jsonb_valid('{"properties": {"a": {"type": "number"}}}', '{"a": 2.5}');
SELECT is_jsonb_valid('{"properties": {"a": {"type": "integer"}}}', '{"a": 2}');
SELECT is_jsonb_valid('{"properties": {"a": {"type": "integer"}}}', '{"a": 2.5}');
--- property is compared with length of key, in this case 4
SELECT is_jsonb_valid('{"properties": {"a": {"type": "inte"}}}', '{"a": 2}');

SELECT is_jsonb_valid('{"properties": {"a": {"type": "integer"}}}', '{"b": 1}');

SELECT is_jsonb_valid('{"type": 1}', '2');
select jsonb_get2('{"a": 2}');
select jsonb_get2('{"a": {"c": 2}}');
select jsonb_get2('{"b": 2}');
