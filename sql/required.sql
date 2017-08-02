-- required validation
-- present required property is valid
SELECT is_jsonb_valid('{"properties":{"foo":{},"bar":{}},"required":["foo"]}', '{"foo":1}');
-- non-present required property is invalid
SELECT is_jsonb_valid('{"properties":{"foo":{},"bar":{}},"required":["foo"]}', '{"bar":1}');
-- ignores arrays
SELECT is_jsonb_valid('{"properties":{"foo":{},"bar":{}},"required":["foo"]}', '[]');
-- ignores strings
SELECT is_jsonb_valid('{"properties":{"foo":{},"bar":{}},"required":["foo"]}', '""');
-- ignores other non-objects
SELECT is_jsonb_valid('{"properties":{"foo":{},"bar":{}},"required":["foo"]}', '12');
-- required default validation
-- not required by default
SELECT is_jsonb_valid('{"properties":{"foo":{}}}', '{}');