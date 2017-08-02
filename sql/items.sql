-- a schema given for items
-- valid items
SELECT is_jsonb_valid('{"items":{"type":"integer"}}', '[1,2,3]');
-- wrong type of items
SELECT is_jsonb_valid('{"items":{"type":"integer"}}', '[1,"x"]');
-- ignores non-arrays
SELECT is_jsonb_valid('{"items":{"type":"integer"}}', '{"foo":"bar"}');
-- JavaScript pseudo-array is valid
SELECT is_jsonb_valid('{"items":{"type":"integer"}}', '{"0":"invalid","length":1}');
-- an array of schemas for items
-- correct types
SELECT is_jsonb_valid('{"items":[{"type":"integer"},{"type":"string"}]}', '[1,"foo"]');
-- wrong types
SELECT is_jsonb_valid('{"items":[{"type":"integer"},{"type":"string"}]}', '["foo",1]');
-- incomplete array of items
SELECT is_jsonb_valid('{"items":[{"type":"integer"},{"type":"string"}]}', '[1]');
-- array with additional items
SELECT is_jsonb_valid('{"items":[{"type":"integer"},{"type":"string"}]}', '[1,"foo",true]');
-- empty array
SELECT is_jsonb_valid('{"items":[{"type":"integer"},{"type":"string"}]}', '[]');
-- JavaScript pseudo-array is valid
SELECT is_jsonb_valid('{"items":[{"type":"integer"},{"type":"string"}]}', '{"0":"invalid","1":"valid","length":2}');