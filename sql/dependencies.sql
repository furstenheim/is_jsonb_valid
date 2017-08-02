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