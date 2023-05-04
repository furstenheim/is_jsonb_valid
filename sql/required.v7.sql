-- required validation
-- present required property is valid
SELECT is_jsonb_valid_draft_v7('{"properties":{"foo":{},"bar":{}},"required":["foo"]}', '{"foo":1}');
-- non-present required property is invalid
SELECT is_jsonb_valid_draft_v7('{"properties":{"foo":{},"bar":{}},"required":["foo"]}', '{"bar":1}');
-- ignores arrays
SELECT is_jsonb_valid_draft_v7('{"properties":{"foo":{},"bar":{}},"required":["foo"]}', '[]');
-- ignores strings
SELECT is_jsonb_valid_draft_v7('{"properties":{"foo":{},"bar":{}},"required":["foo"]}', '""');
-- ignores other non-objects
SELECT is_jsonb_valid_draft_v7('{"properties":{"foo":{},"bar":{}},"required":["foo"]}', '12');
-- required default validation
-- not required by default
SELECT is_jsonb_valid_draft_v7('{"properties":{"foo":{}}}', '{}');
-- required with empty array
-- property not required
SELECT is_jsonb_valid_draft_v7('{"properties":{"foo":{}},"required":[]}', '{}');
-- required with escaped characters
-- object with all properties present is valid
SELECT is_jsonb_valid_draft_v7('{"required":["foo\nbar","foo\"bar","foo\\bar","foo\rbar","foo\tbar","foo\fbar"]}', '{"foo\nbar":1,"foo\"bar":1,"foo\\bar":1,"foo\rbar":1,"foo\tbar":1,"foo\fbar":1}');
-- object with some properties missing is invalid
SELECT is_jsonb_valid_draft_v7('{"required":["foo\nbar","foo\"bar","foo\\bar","foo\rbar","foo\tbar","foo\fbar"]}', '{"foo\nbar":"1","foo\"bar":"1"}');
-- required properties whose names are Javascript object property names
-- ignores arrays
SELECT is_jsonb_valid_draft_v7('{"required":["__proto__","toString","constructor"]}', '[]');
-- ignores other non-objects
SELECT is_jsonb_valid_draft_v7('{"required":["__proto__","toString","constructor"]}', '12');
-- none of the properties mentioned
SELECT is_jsonb_valid_draft_v7('{"required":["__proto__","toString","constructor"]}', '{}');
-- __proto__ present
SELECT is_jsonb_valid_draft_v7('{"required":["__proto__","toString","constructor"]}', '{"__proto__":"foo"}');
-- toString present
SELECT is_jsonb_valid_draft_v7('{"required":["__proto__","toString","constructor"]}', '{"toString":{"length":37}}');
-- constructor present
SELECT is_jsonb_valid_draft_v7('{"required":["__proto__","toString","constructor"]}', '{"constructor":{"length":37}}');
-- all present
SELECT is_jsonb_valid_draft_v7('{"required":["__proto__","toString","constructor"]}', '{"__proto__":12,"toString":{"length":"foo"},"constructor":37}');