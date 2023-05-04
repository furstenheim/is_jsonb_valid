-- evaluating the same schema location against the same data location twice is not a sign of an infinite loop
-- passing case
SELECT is_jsonb_valid_draft_v7('{"definitions":{"int":{"type":"integer"}},"allOf":[{"properties":{"foo":{"$ref":"#/definitions/int"}}},{"additionalProperties":{"$ref":"#/definitions/int"}}]}', '{"foo":1}');
-- failing case
SELECT is_jsonb_valid_draft_v7('{"definitions":{"int":{"type":"integer"}},"allOf":[{"properties":{"foo":{"$ref":"#/definitions/int"}}},{"additionalProperties":{"$ref":"#/definitions/int"}}]}', '{"foo":"a string"}');