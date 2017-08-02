-- additionalItems as schema
-- additional items match schema
SELECT is_jsonb_valid('{"items":[{}],"additionalItems":{"type":"integer"}}', '[null,2,3,4]');
-- additional items do not match schema
SELECT is_jsonb_valid('{"items":[{}],"additionalItems":{"type":"integer"}}', '[null,2,3,"foo"]');
-- items is schema, no additionalItems
-- all items match schema
SELECT is_jsonb_valid('{"items":{},"additionalItems":false}', '[1,2,3,4,5]');
-- array of items with no additionalItems
-- fewer number of items present
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