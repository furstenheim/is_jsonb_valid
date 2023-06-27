-- invalid type for default
-- valid when property is specified
SELECT is_jsonb_valid('{"properties":{"foo":{"type":"integer","default":[]}}}', '{"foo":13}');
-- still valid when the invalid default is used
SELECT is_jsonb_valid('{"properties":{"foo":{"type":"integer","default":[]}}}', '{}');
-- invalid string value for default
-- valid when property is specified
SELECT is_jsonb_valid('{"properties":{"bar":{"type":"string","minLength":4,"default":"bad"}}}', '{"bar":"good"}');
-- still valid when the invalid default is used
SELECT is_jsonb_valid('{"properties":{"bar":{"type":"string","minLength":4,"default":"bad"}}}', '{}');
-- the default keyword does not do anything if the property is missing
-- an explicit property value is checked against maximum (passing)
SELECT is_jsonb_valid('{"type":"object","properties":{"alpha":{"type":"number","maximum":3,"default":5}}}', '{"alpha":1}');
-- an explicit property value is checked against maximum (failing)
SELECT is_jsonb_valid('{"type":"object","properties":{"alpha":{"type":"number","maximum":3,"default":5}}}', '{"alpha":5}');
-- missing properties are not filled in with the default
SELECT is_jsonb_valid('{"type":"object","properties":{"alpha":{"type":"number","maximum":3,"default":5}}}', '{}');