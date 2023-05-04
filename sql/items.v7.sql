-- a schema given for items
-- valid items
SELECT is_jsonb_valid_draft_v7('{"items":{"type":"integer"}}', '[1,2,3]');
-- wrong type of items
SELECT is_jsonb_valid_draft_v7('{"items":{"type":"integer"}}', '[1,"x"]');
-- ignores non-arrays
SELECT is_jsonb_valid_draft_v7('{"items":{"type":"integer"}}', '{"foo":"bar"}');
-- JavaScript pseudo-array is valid
SELECT is_jsonb_valid_draft_v7('{"items":{"type":"integer"}}', '{"0":"invalid","length":1}');
-- an array of schemas for items
-- correct types
SELECT is_jsonb_valid_draft_v7('{"items":[{"type":"integer"},{"type":"string"}]}', '[1,"foo"]');
-- wrong types
SELECT is_jsonb_valid_draft_v7('{"items":[{"type":"integer"},{"type":"string"}]}', '["foo",1]');
-- incomplete array of items
SELECT is_jsonb_valid_draft_v7('{"items":[{"type":"integer"},{"type":"string"}]}', '[1]');
-- array with additional items
SELECT is_jsonb_valid_draft_v7('{"items":[{"type":"integer"},{"type":"string"}]}', '[1,"foo",true]');
-- empty array
SELECT is_jsonb_valid_draft_v7('{"items":[{"type":"integer"},{"type":"string"}]}', '[]');
-- JavaScript pseudo-array is valid
SELECT is_jsonb_valid_draft_v7('{"items":[{"type":"integer"},{"type":"string"}]}', '{"0":"invalid","1":"valid","length":2}');
-- items with boolean schema (true)
-- any array is valid
SELECT is_jsonb_valid_draft_v7('{"items":true}', '[1,"foo",true]');
-- empty array is valid
SELECT is_jsonb_valid_draft_v7('{"items":true}', '[]');
-- items with boolean schema (false)
-- any non-empty array is invalid
SELECT is_jsonb_valid_draft_v7('{"items":false}', '[1,"foo",true]');
-- empty array is valid
SELECT is_jsonb_valid_draft_v7('{"items":false}', '[]');
-- items with boolean schemas
-- array with one item is valid
SELECT is_jsonb_valid_draft_v7('{"items":[true,false]}', '[1]');
-- array with two items is invalid
SELECT is_jsonb_valid_draft_v7('{"items":[true,false]}', '[1,"foo"]');
-- empty array is valid
SELECT is_jsonb_valid_draft_v7('{"items":[true,false]}', '[]');
-- items and subitems
-- valid items
SELECT is_jsonb_valid_draft_v7('{"definitions":{"item":{"type":"array","additionalItems":false,"items":[{"$ref":"#/definitions/sub-item"},{"$ref":"#/definitions/sub-item"}]},"sub-item":{"type":"object","required":["foo"]}},"type":"array","additionalItems":false,"items":[{"$ref":"#/definitions/item"},{"$ref":"#/definitions/item"},{"$ref":"#/definitions/item"}]}', '[[{"foo":null},{"foo":null}],[{"foo":null},{"foo":null}],[{"foo":null},{"foo":null}]]');
-- too many items
SELECT is_jsonb_valid_draft_v7('{"definitions":{"item":{"type":"array","additionalItems":false,"items":[{"$ref":"#/definitions/sub-item"},{"$ref":"#/definitions/sub-item"}]},"sub-item":{"type":"object","required":["foo"]}},"type":"array","additionalItems":false,"items":[{"$ref":"#/definitions/item"},{"$ref":"#/definitions/item"},{"$ref":"#/definitions/item"}]}', '[[{"foo":null},{"foo":null}],[{"foo":null},{"foo":null}],[{"foo":null},{"foo":null}],[{"foo":null},{"foo":null}]]');
-- too many sub-items
SELECT is_jsonb_valid_draft_v7('{"definitions":{"item":{"type":"array","additionalItems":false,"items":[{"$ref":"#/definitions/sub-item"},{"$ref":"#/definitions/sub-item"}]},"sub-item":{"type":"object","required":["foo"]}},"type":"array","additionalItems":false,"items":[{"$ref":"#/definitions/item"},{"$ref":"#/definitions/item"},{"$ref":"#/definitions/item"}]}', '[[{"foo":null},{"foo":null},{"foo":null}],[{"foo":null},{"foo":null}],[{"foo":null},{"foo":null}]]');
-- wrong item
SELECT is_jsonb_valid_draft_v7('{"definitions":{"item":{"type":"array","additionalItems":false,"items":[{"$ref":"#/definitions/sub-item"},{"$ref":"#/definitions/sub-item"}]},"sub-item":{"type":"object","required":["foo"]}},"type":"array","additionalItems":false,"items":[{"$ref":"#/definitions/item"},{"$ref":"#/definitions/item"},{"$ref":"#/definitions/item"}]}', '[{"foo":null},[{"foo":null},{"foo":null}],[{"foo":null},{"foo":null}]]');
-- wrong sub-item
SELECT is_jsonb_valid_draft_v7('{"definitions":{"item":{"type":"array","additionalItems":false,"items":[{"$ref":"#/definitions/sub-item"},{"$ref":"#/definitions/sub-item"}]},"sub-item":{"type":"object","required":["foo"]}},"type":"array","additionalItems":false,"items":[{"$ref":"#/definitions/item"},{"$ref":"#/definitions/item"},{"$ref":"#/definitions/item"}]}', '[[{},{"foo":null}],[{"foo":null},{"foo":null}],[{"foo":null},{"foo":null}]]');
-- fewer items is valid
SELECT is_jsonb_valid_draft_v7('{"definitions":{"item":{"type":"array","additionalItems":false,"items":[{"$ref":"#/definitions/sub-item"},{"$ref":"#/definitions/sub-item"}]},"sub-item":{"type":"object","required":["foo"]}},"type":"array","additionalItems":false,"items":[{"$ref":"#/definitions/item"},{"$ref":"#/definitions/item"},{"$ref":"#/definitions/item"}]}', '[[{"foo":null}],[{"foo":null}]]');
-- nested items
-- valid nested array
SELECT is_jsonb_valid_draft_v7('{"type":"array","items":{"type":"array","items":{"type":"array","items":{"type":"array","items":{"type":"number"}}}}}', '[[[[1]],[[2],[3]]],[[[4],[5],[6]]]]');
-- nested array with invalid type
SELECT is_jsonb_valid_draft_v7('{"type":"array","items":{"type":"array","items":{"type":"array","items":{"type":"array","items":{"type":"number"}}}}}', '[[[["1"]],[[2],[3]]],[[[4],[5],[6]]]]');
-- not deep enough
SELECT is_jsonb_valid_draft_v7('{"type":"array","items":{"type":"array","items":{"type":"array","items":{"type":"array","items":{"type":"number"}}}}}', '[[[1],[2],[3]],[[4],[5],[6]]]');
-- single-form items with null instance elements
-- allows null elements
SELECT is_jsonb_valid_draft_v7('{"items":{"type":"null"}}', '[null]');
-- array-form items with null instance elements
-- allows null elements
SELECT is_jsonb_valid_draft_v7('{"items":[{"type":"null"}]}', '[null]');