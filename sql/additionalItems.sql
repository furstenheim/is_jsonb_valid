-- additionalItems as schema
-- additional items match schema
SELECT is_jsonb_valid('{"items":[{}],"additionalItems":{"type":"integer"}}', '[null,2,3,4]');
-- additional items do not match schema
SELECT is_jsonb_valid('{"items":[{}],"additionalItems":{"type":"integer"}}', '[null,2,3,"foo"]');
-- when items is schema, additionalItems does nothing
-- all items match schema
SELECT is_jsonb_valid('{"items":{},"additionalItems":false}', '[1,2,3,4,5]');
-- array of items with no additionalItems permitted
-- empty array
SELECT is_jsonb_valid('{"items":[{},{},{}],"additionalItems":false}', '[]');
-- fewer number of items present (1)
SELECT is_jsonb_valid('{"items":[{},{},{}],"additionalItems":false}', '[1]');
-- fewer number of items present (2)
SELECT is_jsonb_valid('{"items":[{},{},{}],"additionalItems":false}', '[1,2]');
-- equal number of items present
SELECT is_jsonb_valid('{"items":[{},{},{}],"additionalItems":false}', '[1,2,3]');
-- additional items are not permitted
SELECT is_jsonb_valid('{"items":[{},{},{}],"additionalItems":false}', '[1,2,3,4]');
-- additionalItems as false without items
-- items defaults to empty schema so everything is valid
SELECT is_jsonb_valid('{"additionalItems":false}', '[1,2,3,4,5]');
-- ignores non-arrays
SELECT is_jsonb_valid('{"additionalItems":false}', '{"foo":"bar"}');
-- additionalItems are allowed by default
-- only the first item is validated
SELECT is_jsonb_valid('{"items":[{"type":"integer"}]}', '[1,"foo",false]');
-- additionalItems does not look in applicators, valid case
-- items defined in allOf are not examined
SELECT is_jsonb_valid('{"allOf":[{"items":[{"type":"integer"}]}],"additionalItems":{"type":"boolean"}}', '[1,null]');
-- additionalItems does not look in applicators, invalid case
-- items defined in allOf are not examined
SELECT is_jsonb_valid('{"allOf":[{"items":[{"type":"integer"},{"type":"string"}]}],"items":[{"type":"integer"}],"additionalItems":{"type":"boolean"}}', '[1,"hello"]');
-- items validation adjusts the starting index for additionalItems
-- valid items
SELECT is_jsonb_valid('{"items":[{"type":"string"}],"additionalItems":{"type":"integer"}}', '["x",2,3]');
-- wrong type of second item
SELECT is_jsonb_valid('{"items":[{"type":"string"}],"additionalItems":{"type":"integer"}}', '["x","y"]');
-- additionalItems with null instance elements
-- allows null elements
SELECT is_jsonb_valid('{"additionalItems":{"type":"null"}}', '[null]');