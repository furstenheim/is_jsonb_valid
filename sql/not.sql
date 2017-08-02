-- not
-- allowed
SELECT is_jsonb_valid('{"not":{"type":"integer"}}', '"foo"');
-- disallowed
SELECT is_jsonb_valid('{"not":{"type":"integer"}}', '1');
-- not multiple types
-- valid
SELECT is_jsonb_valid('{"not":{"type":["integer","boolean"]}}', '"foo"');
-- mismatch
SELECT is_jsonb_valid('{"not":{"type":["integer","boolean"]}}', '1');
-- other mismatch
SELECT is_jsonb_valid('{"not":{"type":["integer","boolean"]}}', 'true');
-- not more complex schema
-- match
SELECT is_jsonb_valid('{"not":{"type":"object","properties":{"foo":{"type":"string"}}}}', '1');
-- other match
SELECT is_jsonb_valid('{"not":{"type":"object","properties":{"foo":{"type":"string"}}}}', '{"foo":1}');
-- mismatch
SELECT is_jsonb_valid('{"not":{"type":"object","properties":{"foo":{"type":"string"}}}}', '{"foo":"bar"}');
-- forbidden property
-- property present
SELECT is_jsonb_valid('{"properties":{"foo":{"not":{}}}}', '{"foo":1,"bar":2}');
-- property absent
SELECT is_jsonb_valid('{"properties":{"foo":{"not":{}}}}', '{"bar":1,"baz":2}');