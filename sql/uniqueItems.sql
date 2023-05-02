-- uniqueItems validation
-- unique array of integers is valid
SELECT is_jsonb_valid('{"uniqueItems":true}', '[1,2]');
-- non-unique array of integers is invalid
SELECT is_jsonb_valid('{"uniqueItems":true}', '[1,1]');
-- non-unique array of more than two integers is invalid
SELECT is_jsonb_valid('{"uniqueItems":true}', '[1,2,1]');
-- numbers are unique if mathematically unequal
SELECT is_jsonb_valid('{"uniqueItems":true}', '[1,1,1]');
-- false is not equal to zero
SELECT is_jsonb_valid('{"uniqueItems":true}', '[0,false]');
-- true is not equal to one
SELECT is_jsonb_valid('{"uniqueItems":true}', '[1,true]');
-- unique array of strings is valid
SELECT is_jsonb_valid('{"uniqueItems":true}', '["foo","bar","baz"]');
-- non-unique array of strings is invalid
SELECT is_jsonb_valid('{"uniqueItems":true}', '["foo","bar","foo"]');
-- unique array of objects is valid
SELECT is_jsonb_valid('{"uniqueItems":true}', '[{"foo":"bar"},{"foo":"baz"}]');
-- non-unique array of objects is invalid
SELECT is_jsonb_valid('{"uniqueItems":true}', '[{"foo":"bar"},{"foo":"bar"}]');
-- property order of array of objects is ignored
SELECT is_jsonb_valid('{"uniqueItems":true}', '[{"foo":"bar","bar":"foo"},{"bar":"foo","foo":"bar"}]');
-- unique array of nested objects is valid
SELECT is_jsonb_valid('{"uniqueItems":true}', '[{"foo":{"bar":{"baz":true}}},{"foo":{"bar":{"baz":false}}}]');
-- non-unique array of nested objects is invalid
SELECT is_jsonb_valid('{"uniqueItems":true}', '[{"foo":{"bar":{"baz":true}}},{"foo":{"bar":{"baz":true}}}]');
-- unique array of arrays is valid
SELECT is_jsonb_valid('{"uniqueItems":true}', '[["foo"],["bar"]]');
-- non-unique array of arrays is invalid
SELECT is_jsonb_valid('{"uniqueItems":true}', '[["foo"],["foo"]]');
-- non-unique array of more than two arrays is invalid
SELECT is_jsonb_valid('{"uniqueItems":true}', '[["foo"],["bar"],["foo"]]');
-- 1 and true are unique
SELECT is_jsonb_valid('{"uniqueItems":true}', '[1,true]');
-- 0 and false are unique
SELECT is_jsonb_valid('{"uniqueItems":true}', '[0,false]');
-- [1] and [true] are unique
SELECT is_jsonb_valid('{"uniqueItems":true}', '[[1],[true]]');
-- [0] and [false] are unique
SELECT is_jsonb_valid('{"uniqueItems":true}', '[[0],[false]]');
-- nested [1] and [true] are unique
SELECT is_jsonb_valid('{"uniqueItems":true}', '[[[1],"foo"],[[true],"foo"]]');
-- nested [0] and [false] are unique
SELECT is_jsonb_valid('{"uniqueItems":true}', '[[[0],"foo"],[[false],"foo"]]');
-- unique heterogeneous types are valid
SELECT is_jsonb_valid('{"uniqueItems":true}', '[{},[1],true,null,1,"{}"]');
-- non-unique heterogeneous types are invalid
SELECT is_jsonb_valid('{"uniqueItems":true}', '[{},[1],true,null,{},1]');
-- different objects are unique
SELECT is_jsonb_valid('{"uniqueItems":true}', '[{"a":1,"b":2},{"a":2,"b":1}]');
-- objects are non-unique despite key order
SELECT is_jsonb_valid('{"uniqueItems":true}', '[{"a":1,"b":2},{"b":2,"a":1}]');
-- {"a": false} and {"a": 0} are unique
SELECT is_jsonb_valid('{"uniqueItems":true}', '[{"a":false},{"a":0}]');
-- {"a": true} and {"a": 1} are unique
SELECT is_jsonb_valid('{"uniqueItems":true}', '[{"a":true},{"a":1}]');
-- uniqueItems with an array of items
-- [false, true] from items array is valid
SELECT is_jsonb_valid('{"items":[{"type":"boolean"},{"type":"boolean"}],"uniqueItems":true}', '[false,true]');
-- [true, false] from items array is valid
SELECT is_jsonb_valid('{"items":[{"type":"boolean"},{"type":"boolean"}],"uniqueItems":true}', '[true,false]');
-- [false, false] from items array is not valid
SELECT is_jsonb_valid('{"items":[{"type":"boolean"},{"type":"boolean"}],"uniqueItems":true}', '[false,false]');
-- [true, true] from items array is not valid
SELECT is_jsonb_valid('{"items":[{"type":"boolean"},{"type":"boolean"}],"uniqueItems":true}', '[true,true]');
-- unique array extended from [false, true] is valid
SELECT is_jsonb_valid('{"items":[{"type":"boolean"},{"type":"boolean"}],"uniqueItems":true}', '[false,true,"foo","bar"]');
-- unique array extended from [true, false] is valid
SELECT is_jsonb_valid('{"items":[{"type":"boolean"},{"type":"boolean"}],"uniqueItems":true}', '[true,false,"foo","bar"]');
-- non-unique array extended from [false, true] is not valid
SELECT is_jsonb_valid('{"items":[{"type":"boolean"},{"type":"boolean"}],"uniqueItems":true}', '[false,true,"foo","foo"]');
-- non-unique array extended from [true, false] is not valid
SELECT is_jsonb_valid('{"items":[{"type":"boolean"},{"type":"boolean"}],"uniqueItems":true}', '[true,false,"foo","foo"]');
-- uniqueItems with an array of items and additionalItems=false
-- [false, true] from items array is valid
SELECT is_jsonb_valid('{"items":[{"type":"boolean"},{"type":"boolean"}],"uniqueItems":true,"additionalItems":false}', '[false,true]');
-- [true, false] from items array is valid
SELECT is_jsonb_valid('{"items":[{"type":"boolean"},{"type":"boolean"}],"uniqueItems":true,"additionalItems":false}', '[true,false]');
-- [false, false] from items array is not valid
SELECT is_jsonb_valid('{"items":[{"type":"boolean"},{"type":"boolean"}],"uniqueItems":true,"additionalItems":false}', '[false,false]');
-- [true, true] from items array is not valid
SELECT is_jsonb_valid('{"items":[{"type":"boolean"},{"type":"boolean"}],"uniqueItems":true,"additionalItems":false}', '[true,true]');
-- extra items are invalid even if unique
SELECT is_jsonb_valid('{"items":[{"type":"boolean"},{"type":"boolean"}],"uniqueItems":true,"additionalItems":false}', '[false,true,null]');
-- uniqueItems=false validation
-- unique array of integers is valid
SELECT is_jsonb_valid('{"uniqueItems":false}', '[1,2]');
-- non-unique array of integers is valid
SELECT is_jsonb_valid('{"uniqueItems":false}', '[1,1]');
-- numbers are unique if mathematically unequal
SELECT is_jsonb_valid('{"uniqueItems":false}', '[1,1,1]');
-- false is not equal to zero
SELECT is_jsonb_valid('{"uniqueItems":false}', '[0,false]');
-- true is not equal to one
SELECT is_jsonb_valid('{"uniqueItems":false}', '[1,true]');
-- unique array of objects is valid
SELECT is_jsonb_valid('{"uniqueItems":false}', '[{"foo":"bar"},{"foo":"baz"}]');
-- non-unique array of objects is valid
SELECT is_jsonb_valid('{"uniqueItems":false}', '[{"foo":"bar"},{"foo":"bar"}]');
-- unique array of nested objects is valid
SELECT is_jsonb_valid('{"uniqueItems":false}', '[{"foo":{"bar":{"baz":true}}},{"foo":{"bar":{"baz":false}}}]');
-- non-unique array of nested objects is valid
SELECT is_jsonb_valid('{"uniqueItems":false}', '[{"foo":{"bar":{"baz":true}}},{"foo":{"bar":{"baz":true}}}]');
-- unique array of arrays is valid
SELECT is_jsonb_valid('{"uniqueItems":false}', '[["foo"],["bar"]]');
-- non-unique array of arrays is valid
SELECT is_jsonb_valid('{"uniqueItems":false}', '[["foo"],["foo"]]');
-- 1 and true are unique
SELECT is_jsonb_valid('{"uniqueItems":false}', '[1,true]');
-- 0 and false are unique
SELECT is_jsonb_valid('{"uniqueItems":false}', '[0,false]');
-- unique heterogeneous types are valid
SELECT is_jsonb_valid('{"uniqueItems":false}', '[{},[1],true,null,1]');
-- non-unique heterogeneous types are valid
SELECT is_jsonb_valid('{"uniqueItems":false}', '[{},[1],true,null,{},1]');
-- uniqueItems=false with an array of items
-- [false, true] from items array is valid
SELECT is_jsonb_valid('{"items":[{"type":"boolean"},{"type":"boolean"}],"uniqueItems":false}', '[false,true]');
-- [true, false] from items array is valid
SELECT is_jsonb_valid('{"items":[{"type":"boolean"},{"type":"boolean"}],"uniqueItems":false}', '[true,false]');
-- [false, false] from items array is valid
SELECT is_jsonb_valid('{"items":[{"type":"boolean"},{"type":"boolean"}],"uniqueItems":false}', '[false,false]');
-- [true, true] from items array is valid
SELECT is_jsonb_valid('{"items":[{"type":"boolean"},{"type":"boolean"}],"uniqueItems":false}', '[true,true]');
-- unique array extended from [false, true] is valid
SELECT is_jsonb_valid('{"items":[{"type":"boolean"},{"type":"boolean"}],"uniqueItems":false}', '[false,true,"foo","bar"]');
-- unique array extended from [true, false] is valid
SELECT is_jsonb_valid('{"items":[{"type":"boolean"},{"type":"boolean"}],"uniqueItems":false}', '[true,false,"foo","bar"]');
-- non-unique array extended from [false, true] is valid
SELECT is_jsonb_valid('{"items":[{"type":"boolean"},{"type":"boolean"}],"uniqueItems":false}', '[false,true,"foo","foo"]');
-- non-unique array extended from [true, false] is valid
SELECT is_jsonb_valid('{"items":[{"type":"boolean"},{"type":"boolean"}],"uniqueItems":false}', '[true,false,"foo","foo"]');
-- uniqueItems=false with an array of items and additionalItems=false
-- [false, true] from items array is valid
SELECT is_jsonb_valid('{"items":[{"type":"boolean"},{"type":"boolean"}],"uniqueItems":false,"additionalItems":false}', '[false,true]');
-- [true, false] from items array is valid
SELECT is_jsonb_valid('{"items":[{"type":"boolean"},{"type":"boolean"}],"uniqueItems":false,"additionalItems":false}', '[true,false]');
-- [false, false] from items array is valid
SELECT is_jsonb_valid('{"items":[{"type":"boolean"},{"type":"boolean"}],"uniqueItems":false,"additionalItems":false}', '[false,false]');
-- [true, true] from items array is valid
SELECT is_jsonb_valid('{"items":[{"type":"boolean"},{"type":"boolean"}],"uniqueItems":false,"additionalItems":false}', '[true,true]');
-- extra items are invalid even if unique
SELECT is_jsonb_valid('{"items":[{"type":"boolean"},{"type":"boolean"}],"uniqueItems":false,"additionalItems":false}', '[false,true,null]');