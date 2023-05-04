-- additionalProperties being false does not allow other properties
-- no additional properties is valid
SELECT is_jsonb_valid_draft_v7('{"properties":{"foo":{},"bar":{}},"patternProperties":{"^v":{}},"additionalProperties":false}', '{"foo":1}');
-- an additional property is invalid
SELECT is_jsonb_valid_draft_v7('{"properties":{"foo":{},"bar":{}},"patternProperties":{"^v":{}},"additionalProperties":false}', '{"foo":1,"bar":2,"quux":"boom"}');
-- ignores arrays
SELECT is_jsonb_valid_draft_v7('{"properties":{"foo":{},"bar":{}},"patternProperties":{"^v":{}},"additionalProperties":false}', '[1,2,3]');
-- ignores strings
SELECT is_jsonb_valid_draft_v7('{"properties":{"foo":{},"bar":{}},"patternProperties":{"^v":{}},"additionalProperties":false}', '"foobarbaz"');
-- ignores other non-objects
SELECT is_jsonb_valid_draft_v7('{"properties":{"foo":{},"bar":{}},"patternProperties":{"^v":{}},"additionalProperties":false}', '12');
-- patternProperties are not additional properties
SELECT is_jsonb_valid_draft_v7('{"properties":{"foo":{},"bar":{}},"patternProperties":{"^v":{}},"additionalProperties":false}', '{"foo":1,"vroom":2}');
-- non-ASCII pattern with additionalProperties
-- matching the pattern is valid
SELECT is_jsonb_valid_draft_v7('{"patternProperties":{"^á":{}},"additionalProperties":false}', '{"ármányos":2}');
-- not matching the pattern is invalid
SELECT is_jsonb_valid_draft_v7('{"patternProperties":{"^á":{}},"additionalProperties":false}', '{"élmény":2}');
-- additionalProperties with schema
-- no additional properties is valid
SELECT is_jsonb_valid_draft_v7('{"properties":{"foo":{},"bar":{}},"additionalProperties":{"type":"boolean"}}', '{"foo":1}');
-- an additional valid property is valid
SELECT is_jsonb_valid_draft_v7('{"properties":{"foo":{},"bar":{}},"additionalProperties":{"type":"boolean"}}', '{"foo":1,"bar":2,"quux":true}');
-- an additional invalid property is invalid
SELECT is_jsonb_valid_draft_v7('{"properties":{"foo":{},"bar":{}},"additionalProperties":{"type":"boolean"}}', '{"foo":1,"bar":2,"quux":12}');
-- additionalProperties can exist by itself
-- an additional valid property is valid
SELECT is_jsonb_valid_draft_v7('{"additionalProperties":{"type":"boolean"}}', '{"foo":true}');
-- an additional invalid property is invalid
SELECT is_jsonb_valid_draft_v7('{"additionalProperties":{"type":"boolean"}}', '{"foo":1}');
-- additionalProperties are allowed by default
-- additional properties are allowed
SELECT is_jsonb_valid_draft_v7('{"properties":{"foo":{},"bar":{}}}', '{"foo":1,"bar":2,"quux":true}');
-- additionalProperties does not look in applicators
-- properties defined in allOf are not examined
SELECT is_jsonb_valid_draft_v7('{"allOf":[{"properties":{"foo":{}}}],"additionalProperties":{"type":"boolean"}}', '{"foo":1,"bar":true}');
-- additionalProperties with null valued instance properties
-- allows null values
SELECT is_jsonb_valid_draft_v7('{"additionalProperties":{"type":"null"}}', '{"foo":null}');