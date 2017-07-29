CREATE EXTENSION is_jsonb_valid;
SELECT is_jsonb_valid('{}', '{}');
SELECT is_jsonb_valid('{"type": "object"}', '{}');
SELECT is_jsonb_valid('{"type": "object"}', '2');
SELECT is_jsonb_valid('{"type": "object"}', '{"a": 1}');
SELECT is_jsonb_valid('{"type": "number"}', '2');
SELECT is_jsonb_valid('{"type": "integer"}', '2');
SELECT is_jsonb_valid('{"minimum": 3}', '2');
SELECT is_jsonb_valid('{"minimum": 1}', '2');
SELECT is_jsonb_valid('{"minimum": 2, "exclusiveMinimum": true}', '2');
SELECT is_jsonb_valid('{"type": "integer"}', '2');

SELECT is_jsonb_valid('{"type": "integer"}', '2.5');
SELECT is_jsonb_valid('{"properties": {}}', '2.5');
SELECT is_jsonb_valid('{"properties": {"a": {"type": "null"}}}', '{"a": 1}');
SELECT is_jsonb_valid('{"properties": {"a": {"type": "number"}}}', '{"a": 2.5}');
SELECT is_jsonb_valid('{"properties": {"a": {"type": "integer"}}}', '{"a": 2}');
SELECT is_jsonb_valid('{"properties": {"a": {"type": "integer"}}}', '{"a": 2.5}');
--- property is compared with length of key, in this case 4
SELECT is_jsonb_valid('{"properties": {"a": {"type": "inte"}}}', '{"a": 2}');
SELECT is_jsonb_valid('{"properties": {"a": {"required": true}}}', '{}');
SELECT is_jsonb_valid('{"properties": {"a": {"required": false}}}', '{}');
SELECT is_jsonb_valid('{"properties": {"a": {"required": true}}}', '{"a": 1}');
select is_jsonb_valid('{"items": [{"type": "integer"}, {"type": "number"}]}', '[1, 2.5, 3.5]');
select is_jsonb_valid('{"items": {"type": "integer"}}', '[1, 2, 3]');
select is_jsonb_valid('{"items": {"type": "integer"}}', '[1, 2, 3.5]');
select is_jsonb_valid('{"items": [{"type": "integer"}, {"type": "number"}], "additionalItems": false}', '[1, 2.5, 3.5]');
select is_jsonb_valid('{"items": [{"type": "integer"}, {"type": "number"}], "additionalItems": {"type": "string"}}', '[1, 2.5, 3.5]');
select is_jsonb_valid('{"items": [{"type": "integer"}, {"type": "number"}], "additionalItems": {"type": "number"}}', '[1, 2.5, 3.5]');
SELECT is_jsonb_valid('{"properties": {"a": {"type": "integer"}}}', '{"b": 1}');

SELECT is_jsonb_valid('{"type": 1}', '2');
--select jsonb_get2('{"a": 2}');
--select jsonb_get2('{"a": {"c": 2}}');
--select jsonb_get2('{"b": 2}');
