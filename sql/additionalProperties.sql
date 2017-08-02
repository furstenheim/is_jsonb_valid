-- additionalProperties being false does not allow other properties
-- no additional properties is valid
SELECT is_jsonb_valid('{"properties":{"foo":{},"bar":{}},"patternProperties":{"^v":{}},"additionalProperties":false}', '{"foo":1}');
-- an additional property is invalid
SELECT is_jsonb_valid('{"properties":{"foo":{},"bar":{}},"patternProperties":{"^v":{}},"additionalProperties":false}', '{"foo":1,"bar":2,"quux":"boom"}');
-- ignores arrays
SELECT is_jsonb_valid('{"properties":{"foo":{},"bar":{}},"patternProperties":{"^v":{}},"additionalProperties":false}', '[1,2,3]');
-- ignores strings
SELECT is_jsonb_valid('{"properties":{"foo":{},"bar":{}},"patternProperties":{"^v":{}},"additionalProperties":false}', '"foobarbaz"');
-- ignores other non-objects
SELECT is_jsonb_valid('{"properties":{"foo":{},"bar":{}},"patternProperties":{"^v":{}},"additionalProperties":false}', '12');
-- patternProperties are not additional properties
SELECT is_jsonb_valid('{"properties":{"foo":{},"bar":{}},"patternProperties":{"^v":{}},"additionalProperties":false}', '{"foo":1,"vroom":2}');
-- additionalProperties allows a schema which should validate
-- no additional properties is valid
SELECT is_jsonb_valid('{"properties":{"foo":{},"bar":{}},"additionalProperties":{"type":"boolean"}}', '{"foo":1}');
-- an additional valid property is valid
SELECT is_jsonb_valid('{"properties":{"foo":{},"bar":{}},"additionalProperties":{"type":"boolean"}}', '{"foo":1,"bar":2,"quux":true}');
-- an additional invalid property is invalid
SELECT is_jsonb_valid('{"properties":{"foo":{},"bar":{}},"additionalProperties":{"type":"boolean"}}', '{"foo":1,"bar":2,"quux":12}');
-- additionalProperties can exist by itself
-- an additional valid property is valid
SELECT is_jsonb_valid('{"additionalProperties":{"type":"boolean"}}', '{"foo":true}');
-- an additional invalid property is invalid
SELECT is_jsonb_valid('{"additionalProperties":{"type":"boolean"}}', '{"foo":1}');
-- additionalProperties are allowed by default
-- additional properties are allowed
SELECT is_jsonb_valid('{"properties":{"foo":{},"bar":{}}}', '{"foo":1,"bar":2,"quux":true}');