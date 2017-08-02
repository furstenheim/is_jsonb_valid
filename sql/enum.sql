-- simple enum validation
-- one of the enum is valid
SELECT is_jsonb_valid('{"enum":[1,2,3]}', '1');
-- something else is invalid
SELECT is_jsonb_valid('{"enum":[1,2,3]}', '4');
-- heterogeneous enum validation
-- one of the enum is valid
SELECT is_jsonb_valid('{"enum":[6,"foo",[],true,{"foo":12}]}', '[]');
-- something else is invalid
SELECT is_jsonb_valid('{"enum":[6,"foo",[],true,{"foo":12}]}', 'null');
-- objects are deep compared
SELECT is_jsonb_valid('{"enum":[6,"foo",[],true,{"foo":12}]}', '{"foo":false}');
-- enums in properties
-- both properties are valid
SELECT is_jsonb_valid('{"type":"object","properties":{"foo":{"enum":["foo"]},"bar":{"enum":["bar"]}},"required":["bar"]}', '{"foo":"foo","bar":"bar"}');
-- missing optional property is valid
SELECT is_jsonb_valid('{"type":"object","properties":{"foo":{"enum":["foo"]},"bar":{"enum":["bar"]}},"required":["bar"]}', '{"bar":"bar"}');
-- missing required property is invalid
SELECT is_jsonb_valid('{"type":"object","properties":{"foo":{"enum":["foo"]},"bar":{"enum":["bar"]}},"required":["bar"]}', '{"foo":"foo"}');
-- missing all properties is invalid
SELECT is_jsonb_valid('{"type":"object","properties":{"foo":{"enum":["foo"]},"bar":{"enum":["bar"]}},"required":["bar"]}', '{}');