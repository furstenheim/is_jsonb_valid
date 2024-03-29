-- id inside an enum is not a real identifier
-- exact match to enum, and type matches
SELECT is_jsonb_valid_draft_v7('{"definitions":{"id_in_enum":{"enum":[{"$id":"https://localhost:1234/id/my_identifier.json","type":"null"}]},"real_id_in_schema":{"$id":"https://localhost:1234/id/my_identifier.json","type":"string"},"zzz_id_in_const":{"const":{"$id":"https://localhost:1234/id/my_identifier.json","type":"null"}}},"anyOf":[{"$ref":"#/definitions/id_in_enum"},{"$ref":"https://localhost:1234/id/my_identifier.json"}]}', '{"$id":"https://localhost:1234/id/my_identifier.json","type":"null"}');
-- non-schema object containing a plain-name $id property
-- skip traversing definition for a valid result
SELECT is_jsonb_valid_draft_v7('{"definitions":{"const_not_anchor":{"const":{"$id":"#not_a_real_anchor"}}},"if":{"const":"skip not_a_real_anchor"},"then":true,"else":{"$ref":"#/definitions/const_not_anchor"}}', '"skip not_a_real_anchor"');
-- const at const_not_anchor does not match
SELECT is_jsonb_valid_draft_v7('{"definitions":{"const_not_anchor":{"const":{"$id":"#not_a_real_anchor"}}},"if":{"const":"skip not_a_real_anchor"},"then":true,"else":{"$ref":"#/definitions/const_not_anchor"}}', '1');
-- non-schema object containing an $id property
-- skip traversing definition for a valid result
SELECT is_jsonb_valid_draft_v7('{"definitions":{"const_not_id":{"const":{"$id":"not_a_real_id"}}},"if":{"const":"skip not_a_real_id"},"then":true,"else":{"$ref":"#/definitions/const_not_id"}}', '"skip not_a_real_id"');
-- const at const_not_id does not match
SELECT is_jsonb_valid_draft_v7('{"definitions":{"const_not_id":{"const":{"$id":"not_a_real_id"}}},"if":{"const":"skip not_a_real_id"},"then":true,"else":{"$ref":"#/definitions/const_not_id"}}', '1');