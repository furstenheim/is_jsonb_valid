-- dependencies
-- neither
SELECT is_jsonb_valid('{"dependencies":{"bar":["foo"]}}', '{}');
-- nondependant
SELECT is_jsonb_valid('{"dependencies":{"bar":["foo"]}}', '{"foo":1}');
-- with dependency
SELECT is_jsonb_valid('{"dependencies":{"bar":["foo"]}}', '{"foo":1,"bar":2}');
-- missing dependency
SELECT is_jsonb_valid('{"dependencies":{"bar":["foo"]}}', '{"bar":2}');
-- ignores arrays
SELECT is_jsonb_valid('{"dependencies":{"bar":["foo"]}}', '["bar"]');
-- ignores strings
SELECT is_jsonb_valid('{"dependencies":{"bar":["foo"]}}', '"foobar"');
-- ignores other non-objects
SELECT is_jsonb_valid('{"dependencies":{"bar":["foo"]}}', '12');
-- multiple dependencies
-- neither
SELECT is_jsonb_valid('{"dependencies":{"quux":["foo","bar"]}}', '{}');
-- nondependants
SELECT is_jsonb_valid('{"dependencies":{"quux":["foo","bar"]}}', '{"foo":1,"bar":2}');
-- with dependencies
SELECT is_jsonb_valid('{"dependencies":{"quux":["foo","bar"]}}', '{"foo":1,"bar":2,"quux":3}');
-- missing dependency
SELECT is_jsonb_valid('{"dependencies":{"quux":["foo","bar"]}}', '{"foo":1,"quux":2}');
-- missing other dependency
SELECT is_jsonb_valid('{"dependencies":{"quux":["foo","bar"]}}', '{"bar":1,"quux":2}');
-- missing both dependencies
SELECT is_jsonb_valid('{"dependencies":{"quux":["foo","bar"]}}', '{"quux":1}');
-- multiple dependencies subschema
-- valid
SELECT is_jsonb_valid('{"dependencies":{"bar":{"properties":{"foo":{"type":"integer"},"bar":{"type":"integer"}}}}}', '{"foo":1,"bar":2}');
-- no dependency
SELECT is_jsonb_valid('{"dependencies":{"bar":{"properties":{"foo":{"type":"integer"},"bar":{"type":"integer"}}}}}', '{"foo":"quux"}');
-- wrong type
SELECT is_jsonb_valid('{"dependencies":{"bar":{"properties":{"foo":{"type":"integer"},"bar":{"type":"integer"}}}}}', '{"foo":"quux","bar":2}');
-- wrong type other
SELECT is_jsonb_valid('{"dependencies":{"bar":{"properties":{"foo":{"type":"integer"},"bar":{"type":"integer"}}}}}', '{"foo":2,"bar":"quux"}');
-- wrong type both
SELECT is_jsonb_valid('{"dependencies":{"bar":{"properties":{"foo":{"type":"integer"},"bar":{"type":"integer"}}}}}', '{"foo":"quux","bar":"quux"}');
-- dependencies with escaped characters
-- valid object 1
SELECT is_jsonb_valid('{"dependencies":{"foo\nbar":["foo\rbar"],"foo\tbar":{"minProperties":4},"foo''bar":{"required":["foo\"bar"]},"foo\"bar":["foo''bar"]}}', '{"foo\nbar":1,"foo\rbar":2}');
-- valid object 2
SELECT is_jsonb_valid('{"dependencies":{"foo\nbar":["foo\rbar"],"foo\tbar":{"minProperties":4},"foo''bar":{"required":["foo\"bar"]},"foo\"bar":["foo''bar"]}}', '{"foo\tbar":1,"a":2,"b":3,"c":4}');
-- valid object 3
SELECT is_jsonb_valid('{"dependencies":{"foo\nbar":["foo\rbar"],"foo\tbar":{"minProperties":4},"foo''bar":{"required":["foo\"bar"]},"foo\"bar":["foo''bar"]}}', '{"foo''bar":1,"foo\"bar":2}');
-- invalid object 1
SELECT is_jsonb_valid('{"dependencies":{"foo\nbar":["foo\rbar"],"foo\tbar":{"minProperties":4},"foo''bar":{"required":["foo\"bar"]},"foo\"bar":["foo''bar"]}}', '{"foo\nbar":1,"foo":2}');
-- invalid object 2
SELECT is_jsonb_valid('{"dependencies":{"foo\nbar":["foo\rbar"],"foo\tbar":{"minProperties":4},"foo''bar":{"required":["foo\"bar"]},"foo\"bar":["foo''bar"]}}', '{"foo\tbar":1,"a":2}');
-- invalid object 3
SELECT is_jsonb_valid('{"dependencies":{"foo\nbar":["foo\rbar"],"foo\tbar":{"minProperties":4},"foo''bar":{"required":["foo\"bar"]},"foo\"bar":["foo''bar"]}}', '{"foo''bar":1}');
-- invalid object 4
SELECT is_jsonb_valid('{"dependencies":{"foo\nbar":["foo\rbar"],"foo\tbar":{"minProperties":4},"foo''bar":{"required":["foo\"bar"]},"foo\"bar":["foo''bar"]}}', '{"foo\"bar":2}');
-- dependent subschema incompatible with root
-- matches root
SELECT is_jsonb_valid('{"properties":{"foo":{}},"dependencies":{"foo":{"properties":{"bar":{}},"additionalProperties":false}}}', '{"foo":1}');
-- matches dependency
SELECT is_jsonb_valid('{"properties":{"foo":{}},"dependencies":{"foo":{"properties":{"bar":{}},"additionalProperties":false}}}', '{"bar":1}');
-- matches both
SELECT is_jsonb_valid('{"properties":{"foo":{}},"dependencies":{"foo":{"properties":{"bar":{}},"additionalProperties":false}}}', '{"foo":1,"bar":2}');
-- no dependency
SELECT is_jsonb_valid('{"properties":{"foo":{}},"dependencies":{"foo":{"properties":{"bar":{}},"additionalProperties":false}}}', '{"baz":1}');