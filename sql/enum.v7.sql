-- simple enum validation
-- one of the enum is valid
SELECT is_jsonb_valid_draft_v7('{"enum":[1,2,3]}', '1');
-- something else is invalid
SELECT is_jsonb_valid_draft_v7('{"enum":[1,2,3]}', '4');
-- heterogeneous enum validation
-- one of the enum is valid
SELECT is_jsonb_valid_draft_v7('{"enum":[6,"foo",[],true,{"foo":12}]}', '[]');
-- something else is invalid
SELECT is_jsonb_valid_draft_v7('{"enum":[6,"foo",[],true,{"foo":12}]}', 'null');
-- objects are deep compared
SELECT is_jsonb_valid_draft_v7('{"enum":[6,"foo",[],true,{"foo":12}]}', '{"foo":false}');
-- valid object matches
SELECT is_jsonb_valid_draft_v7('{"enum":[6,"foo",[],true,{"foo":12}]}', '{"foo":12}');
-- extra properties in object is invalid
SELECT is_jsonb_valid_draft_v7('{"enum":[6,"foo",[],true,{"foo":12}]}', '{"foo":12,"boo":42}');
-- heterogeneous enum-with-null validation
-- null is valid
SELECT is_jsonb_valid_draft_v7('{"enum":[6,null]}', 'null');
-- number is valid
SELECT is_jsonb_valid_draft_v7('{"enum":[6,null]}', '6');
-- something else is invalid
SELECT is_jsonb_valid_draft_v7('{"enum":[6,null]}', '"test"');
-- enums in properties
-- both properties are valid
SELECT is_jsonb_valid_draft_v7('{"type":"object","properties":{"foo":{"enum":["foo"]},"bar":{"enum":["bar"]}},"required":["bar"]}', '{"foo":"foo","bar":"bar"}');
-- wrong foo value
SELECT is_jsonb_valid_draft_v7('{"type":"object","properties":{"foo":{"enum":["foo"]},"bar":{"enum":["bar"]}},"required":["bar"]}', '{"foo":"foot","bar":"bar"}');
-- wrong bar value
SELECT is_jsonb_valid_draft_v7('{"type":"object","properties":{"foo":{"enum":["foo"]},"bar":{"enum":["bar"]}},"required":["bar"]}', '{"foo":"foo","bar":"bart"}');
-- missing optional property is valid
SELECT is_jsonb_valid_draft_v7('{"type":"object","properties":{"foo":{"enum":["foo"]},"bar":{"enum":["bar"]}},"required":["bar"]}', '{"bar":"bar"}');
-- missing required property is invalid
SELECT is_jsonb_valid_draft_v7('{"type":"object","properties":{"foo":{"enum":["foo"]},"bar":{"enum":["bar"]}},"required":["bar"]}', '{"foo":"foo"}');
-- missing all properties is invalid
SELECT is_jsonb_valid_draft_v7('{"type":"object","properties":{"foo":{"enum":["foo"]},"bar":{"enum":["bar"]}},"required":["bar"]}', '{}');
-- enum with escaped characters
-- member 1 is valid
SELECT is_jsonb_valid_draft_v7('{"enum":["foo\nbar","foo\rbar"]}', '"foo\nbar"');
-- member 2 is valid
SELECT is_jsonb_valid_draft_v7('{"enum":["foo\nbar","foo\rbar"]}', '"foo\rbar"');
-- another string is invalid
SELECT is_jsonb_valid_draft_v7('{"enum":["foo\nbar","foo\rbar"]}', '"abc"');
-- enum with false does not match 0
-- false is valid
SELECT is_jsonb_valid_draft_v7('{"enum":[false]}', 'false');
-- integer zero is invalid
SELECT is_jsonb_valid_draft_v7('{"enum":[false]}', '0');
-- float zero is invalid
SELECT is_jsonb_valid_draft_v7('{"enum":[false]}', '0');
-- enum with true does not match 1
-- true is valid
SELECT is_jsonb_valid_draft_v7('{"enum":[true]}', 'true');
-- integer one is invalid
SELECT is_jsonb_valid_draft_v7('{"enum":[true]}', '1');
-- float one is invalid
SELECT is_jsonb_valid_draft_v7('{"enum":[true]}', '1');
-- enum with 0 does not match false
-- false is invalid
SELECT is_jsonb_valid_draft_v7('{"enum":[0]}', 'false');
-- integer zero is valid
SELECT is_jsonb_valid_draft_v7('{"enum":[0]}', '0');
-- float zero is valid
SELECT is_jsonb_valid_draft_v7('{"enum":[0]}', '0');
-- enum with 1 does not match true
-- true is invalid
SELECT is_jsonb_valid_draft_v7('{"enum":[1]}', 'true');
-- integer one is valid
SELECT is_jsonb_valid_draft_v7('{"enum":[1]}', '1');
-- float one is valid
SELECT is_jsonb_valid_draft_v7('{"enum":[1]}', '1');