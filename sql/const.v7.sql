-- const validation
-- same value is valid
SELECT is_jsonb_valid_draft_v7('{"const":2}', '2');
-- another value is invalid
SELECT is_jsonb_valid_draft_v7('{"const":2}', '5');
-- another type is invalid
SELECT is_jsonb_valid_draft_v7('{"const":2}', '"a"');
-- const with object
-- same object is valid
SELECT is_jsonb_valid_draft_v7('{"const":{"foo":"bar","baz":"bax"}}', '{"foo":"bar","baz":"bax"}');
-- same object with different property order is valid
SELECT is_jsonb_valid_draft_v7('{"const":{"foo":"bar","baz":"bax"}}', '{"baz":"bax","foo":"bar"}');
-- another object is invalid
SELECT is_jsonb_valid_draft_v7('{"const":{"foo":"bar","baz":"bax"}}', '{"foo":"bar"}');
-- another type is invalid
SELECT is_jsonb_valid_draft_v7('{"const":{"foo":"bar","baz":"bax"}}', '[1,2]');
-- const with array
-- same array is valid
SELECT is_jsonb_valid_draft_v7('{"const":[{"foo":"bar"}]}', '[{"foo":"bar"}]');
-- another array item is invalid
SELECT is_jsonb_valid_draft_v7('{"const":[{"foo":"bar"}]}', '[2]');
-- array with additional items is invalid
SELECT is_jsonb_valid_draft_v7('{"const":[{"foo":"bar"}]}', '[1,2,3]');
-- const with null
-- null is valid
SELECT is_jsonb_valid_draft_v7('{"const":null}', 'null');
-- not null is invalid
SELECT is_jsonb_valid_draft_v7('{"const":null}', '0');
-- const with false does not match 0
-- false is valid
SELECT is_jsonb_valid_draft_v7('{"const":false}', 'false');
-- integer zero is invalid
SELECT is_jsonb_valid_draft_v7('{"const":false}', '0');
-- float zero is invalid
SELECT is_jsonb_valid_draft_v7('{"const":false}', '0');
-- const with true does not match 1
-- true is valid
SELECT is_jsonb_valid_draft_v7('{"const":true}', 'true');
-- integer one is invalid
SELECT is_jsonb_valid_draft_v7('{"const":true}', '1');
-- float one is invalid
SELECT is_jsonb_valid_draft_v7('{"const":true}', '1');
-- const with [false] does not match [0]
-- [false] is valid
SELECT is_jsonb_valid_draft_v7('{"const":[false]}', '[false]');
-- [0] is invalid
SELECT is_jsonb_valid_draft_v7('{"const":[false]}', '[0]');
-- [0.0] is invalid
SELECT is_jsonb_valid_draft_v7('{"const":[false]}', '[0]');
-- const with [true] does not match [1]
-- [true] is valid
SELECT is_jsonb_valid_draft_v7('{"const":[true]}', '[true]');
-- [1] is invalid
SELECT is_jsonb_valid_draft_v7('{"const":[true]}', '[1]');
-- [1.0] is invalid
SELECT is_jsonb_valid_draft_v7('{"const":[true]}', '[1]');
-- const with {"a": false} does not match {"a": 0}
-- {"a": false} is valid
SELECT is_jsonb_valid_draft_v7('{"const":{"a":false}}', '{"a":false}');
-- {"a": 0} is invalid
SELECT is_jsonb_valid_draft_v7('{"const":{"a":false}}', '{"a":0}');
-- {"a": 0.0} is invalid
SELECT is_jsonb_valid_draft_v7('{"const":{"a":false}}', '{"a":0}');
-- const with {"a": true} does not match {"a": 1}
-- {"a": true} is valid
SELECT is_jsonb_valid_draft_v7('{"const":{"a":true}}', '{"a":true}');
-- {"a": 1} is invalid
SELECT is_jsonb_valid_draft_v7('{"const":{"a":true}}', '{"a":1}');
-- {"a": 1.0} is invalid
SELECT is_jsonb_valid_draft_v7('{"const":{"a":true}}', '{"a":1}');
-- const with 0 does not match other zero-like types
-- false is invalid
SELECT is_jsonb_valid_draft_v7('{"const":0}', 'false');
-- integer zero is valid
SELECT is_jsonb_valid_draft_v7('{"const":0}', '0');
-- float zero is valid
SELECT is_jsonb_valid_draft_v7('{"const":0}', '0');
-- empty object is invalid
SELECT is_jsonb_valid_draft_v7('{"const":0}', '{}');
-- empty array is invalid
SELECT is_jsonb_valid_draft_v7('{"const":0}', '[]');
-- empty string is invalid
SELECT is_jsonb_valid_draft_v7('{"const":0}', '""');
-- const with 1 does not match true
-- true is invalid
SELECT is_jsonb_valid_draft_v7('{"const":1}', 'true');
-- integer one is valid
SELECT is_jsonb_valid_draft_v7('{"const":1}', '1');
-- float one is valid
SELECT is_jsonb_valid_draft_v7('{"const":1}', '1');
-- const with -2.0 matches integer and float types
-- integer -2 is valid
SELECT is_jsonb_valid_draft_v7('{"const":-2}', '-2');
-- integer 2 is invalid
SELECT is_jsonb_valid_draft_v7('{"const":-2}', '2');
-- float -2.0 is valid
SELECT is_jsonb_valid_draft_v7('{"const":-2}', '-2');
-- float 2.0 is invalid
SELECT is_jsonb_valid_draft_v7('{"const":-2}', '2');
-- float -2.00001 is invalid
SELECT is_jsonb_valid_draft_v7('{"const":-2}', '-2.00001');
-- float and integers are equal up to 64-bit representation limits
-- integer is valid
SELECT is_jsonb_valid_draft_v7('{"const":9007199254740992}', '9007199254740992');
-- integer minus one is invalid
SELECT is_jsonb_valid_draft_v7('{"const":9007199254740992}', '9007199254740991');
-- float is valid
SELECT is_jsonb_valid_draft_v7('{"const":9007199254740992}', '9007199254740992');
-- float minus one is invalid
SELECT is_jsonb_valid_draft_v7('{"const":9007199254740992}', '9007199254740991');
-- nul characters in strings
-- match string with nul
SELECT is_jsonb_valid_draft_v7('{"const":"hello\u0000there"}', '"hello\u0000there"');
-- do not match string lacking nul
SELECT is_jsonb_valid_draft_v7('{"const":"hello\u0000there"}', '"hellothere"');