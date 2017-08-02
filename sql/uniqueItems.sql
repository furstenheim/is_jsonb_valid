-- uniqueItems validation
-- unique array of integers is valid
SELECT is_jsonb_valid('{"uniqueItems":true}', '[1,2]');
-- non-unique array of integers is invalid
SELECT is_jsonb_valid('{"uniqueItems":true}', '[1,1]');
-- numbers are unique if mathematically unequal
SELECT is_jsonb_valid('{"uniqueItems":true}', '[1,1,1]');
-- unique array of objects is valid
SELECT is_jsonb_valid('{"uniqueItems":true}', '[{"foo":"bar"},{"foo":"baz"}]');
-- non-unique array of objects is invalid
SELECT is_jsonb_valid('{"uniqueItems":true}', '[{"foo":"bar"},{"foo":"bar"}]');
-- unique array of nested objects is valid
SELECT is_jsonb_valid('{"uniqueItems":true}', '[{"foo":{"bar":{"baz":true}}},{"foo":{"bar":{"baz":false}}}]');
-- non-unique array of nested objects is invalid
SELECT is_jsonb_valid('{"uniqueItems":true}', '[{"foo":{"bar":{"baz":true}}},{"foo":{"bar":{"baz":true}}}]');
-- unique array of arrays is valid
SELECT is_jsonb_valid('{"uniqueItems":true}', '[["foo"],["bar"]]');
-- non-unique array of arrays is invalid
SELECT is_jsonb_valid('{"uniqueItems":true}', '[["foo"],["foo"]]');
-- 1 and true are unique
SELECT is_jsonb_valid('{"uniqueItems":true}', '[1,true]');
-- 0 and false are unique
SELECT is_jsonb_valid('{"uniqueItems":true}', '[0,false]');
-- unique heterogeneous types are valid
SELECT is_jsonb_valid('{"uniqueItems":true}', '[{},[1],true,null,1]');
-- non-unique heterogeneous types are invalid
SELECT is_jsonb_valid('{"uniqueItems":true}', '[{},[1],true,null,{},1]');