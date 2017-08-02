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