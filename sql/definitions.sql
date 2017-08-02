-- valid definition
-- valid definition schema
SELECT is_jsonb_valid('{"$ref":"http://json-schema.org/draft-04/schema#"}', '{"definitions":{"foo":{"type":"integer"}}}');
-- invalid definition
-- invalid definition schema
SELECT is_jsonb_valid('{"$ref":"http://json-schema.org/draft-04/schema#"}', '{"definitions":{"foo":{"type":1}}}');