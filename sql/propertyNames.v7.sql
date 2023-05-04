-- propertyNames validation
-- all property names valid
SELECT is_jsonb_valid_draft_v7('{"propertyNames":{"maxLength":3}}', '{"f":{},"foo":{}}');
-- some property names invalid
SELECT is_jsonb_valid_draft_v7('{"propertyNames":{"maxLength":3}}', '{"foo":{},"foobar":{}}');
-- object without properties is valid
SELECT is_jsonb_valid_draft_v7('{"propertyNames":{"maxLength":3}}', '{}');
-- ignores arrays
SELECT is_jsonb_valid_draft_v7('{"propertyNames":{"maxLength":3}}', '[1,2,3,4]');
-- ignores strings
SELECT is_jsonb_valid_draft_v7('{"propertyNames":{"maxLength":3}}', '"foobar"');
-- ignores other non-objects
SELECT is_jsonb_valid_draft_v7('{"propertyNames":{"maxLength":3}}', '12');
-- propertyNames validation with pattern
-- matching property names valid
SELECT is_jsonb_valid_draft_v7('{"propertyNames":{"pattern":"^a+$"}}', '{"a":{},"aa":{},"aaa":{}}');
-- non-matching property name is invalid
SELECT is_jsonb_valid_draft_v7('{"propertyNames":{"pattern":"^a+$"}}', '{"aaA":{}}');
-- object without properties is valid
SELECT is_jsonb_valid_draft_v7('{"propertyNames":{"pattern":"^a+$"}}', '{}');
-- propertyNames with boolean schema true
-- object with any properties is valid
SELECT is_jsonb_valid_draft_v7('{"propertyNames":true}', '{"foo":1}');
-- empty object is valid
SELECT is_jsonb_valid_draft_v7('{"propertyNames":true}', '{}');
-- propertyNames with boolean schema false
-- object with any properties is invalid
SELECT is_jsonb_valid_draft_v7('{"propertyNames":false}', '{"foo":1}');
-- empty object is valid
SELECT is_jsonb_valid_draft_v7('{"propertyNames":false}', '{}');