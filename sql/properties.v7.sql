-- object properties validation
-- both properties present and valid is valid
SELECT is_jsonb_valid_draft_v7('{"properties":{"foo":{"type":"integer"},"bar":{"type":"string"}}}', '{"foo":1,"bar":"baz"}');
-- one property invalid is invalid
SELECT is_jsonb_valid_draft_v7('{"properties":{"foo":{"type":"integer"},"bar":{"type":"string"}}}', '{"foo":1,"bar":{}}');
-- both properties invalid is invalid
SELECT is_jsonb_valid_draft_v7('{"properties":{"foo":{"type":"integer"},"bar":{"type":"string"}}}', '{"foo":[],"bar":{}}');
-- doesn't invalidate other properties
SELECT is_jsonb_valid_draft_v7('{"properties":{"foo":{"type":"integer"},"bar":{"type":"string"}}}', '{"quux":[]}');
-- ignores arrays
SELECT is_jsonb_valid_draft_v7('{"properties":{"foo":{"type":"integer"},"bar":{"type":"string"}}}', '[]');
-- ignores other non-objects
SELECT is_jsonb_valid_draft_v7('{"properties":{"foo":{"type":"integer"},"bar":{"type":"string"}}}', '12');
-- properties, patternProperties, additionalProperties interaction
-- property validates property
SELECT is_jsonb_valid_draft_v7('{"properties":{"foo":{"type":"array","maxItems":3},"bar":{"type":"array"}},"patternProperties":{"f.o":{"minItems":2}},"additionalProperties":{"type":"integer"}}', '{"foo":[1,2]}');
-- property invalidates property
SELECT is_jsonb_valid_draft_v7('{"properties":{"foo":{"type":"array","maxItems":3},"bar":{"type":"array"}},"patternProperties":{"f.o":{"minItems":2}},"additionalProperties":{"type":"integer"}}', '{"foo":[1,2,3,4]}');
-- patternProperty invalidates property
SELECT is_jsonb_valid_draft_v7('{"properties":{"foo":{"type":"array","maxItems":3},"bar":{"type":"array"}},"patternProperties":{"f.o":{"minItems":2}},"additionalProperties":{"type":"integer"}}', '{"foo":[]}');
-- patternProperty validates nonproperty
SELECT is_jsonb_valid_draft_v7('{"properties":{"foo":{"type":"array","maxItems":3},"bar":{"type":"array"}},"patternProperties":{"f.o":{"minItems":2}},"additionalProperties":{"type":"integer"}}', '{"fxo":[1,2]}');
-- patternProperty invalidates nonproperty
SELECT is_jsonb_valid_draft_v7('{"properties":{"foo":{"type":"array","maxItems":3},"bar":{"type":"array"}},"patternProperties":{"f.o":{"minItems":2}},"additionalProperties":{"type":"integer"}}', '{"fxo":[]}');
-- additionalProperty ignores property
SELECT is_jsonb_valid_draft_v7('{"properties":{"foo":{"type":"array","maxItems":3},"bar":{"type":"array"}},"patternProperties":{"f.o":{"minItems":2}},"additionalProperties":{"type":"integer"}}', '{"bar":[]}');
-- additionalProperty validates others
SELECT is_jsonb_valid_draft_v7('{"properties":{"foo":{"type":"array","maxItems":3},"bar":{"type":"array"}},"patternProperties":{"f.o":{"minItems":2}},"additionalProperties":{"type":"integer"}}', '{"quux":3}');
-- additionalProperty invalidates others
SELECT is_jsonb_valid_draft_v7('{"properties":{"foo":{"type":"array","maxItems":3},"bar":{"type":"array"}},"patternProperties":{"f.o":{"minItems":2}},"additionalProperties":{"type":"integer"}}', '{"quux":"foo"}');
-- properties with boolean schema
-- no property present is valid
SELECT is_jsonb_valid_draft_v7('{"properties":{"foo":true,"bar":false}}', '{}');
-- only 'true' property present is valid
SELECT is_jsonb_valid_draft_v7('{"properties":{"foo":true,"bar":false}}', '{"foo":1}');
-- only 'false' property present is invalid
SELECT is_jsonb_valid_draft_v7('{"properties":{"foo":true,"bar":false}}', '{"bar":2}');
-- both properties present is invalid
SELECT is_jsonb_valid_draft_v7('{"properties":{"foo":true,"bar":false}}', '{"foo":1,"bar":2}');
-- properties with escaped characters
-- object with all numbers is valid
SELECT is_jsonb_valid_draft_v7('{"properties":{"foo\nbar":{"type":"number"},"foo\"bar":{"type":"number"},"foo\\bar":{"type":"number"},"foo\rbar":{"type":"number"},"foo\tbar":{"type":"number"},"foo\fbar":{"type":"number"}}}', '{"foo\nbar":1,"foo\"bar":1,"foo\\bar":1,"foo\rbar":1,"foo\tbar":1,"foo\fbar":1}');
-- object with strings is invalid
SELECT is_jsonb_valid_draft_v7('{"properties":{"foo\nbar":{"type":"number"},"foo\"bar":{"type":"number"},"foo\\bar":{"type":"number"},"foo\rbar":{"type":"number"},"foo\tbar":{"type":"number"},"foo\fbar":{"type":"number"}}}', '{"foo\nbar":"1","foo\"bar":"1","foo\\bar":"1","foo\rbar":"1","foo\tbar":"1","foo\fbar":"1"}');
-- properties with null valued instance properties
-- allows null values
SELECT is_jsonb_valid_draft_v7('{"properties":{"foo":{"type":"null"}}}', '{"foo":null}');
-- properties whose names are Javascript object property names
-- ignores arrays
SELECT is_jsonb_valid_draft_v7('{"properties":{"__proto__":{"type":"number"},"toString":{"properties":{"length":{"type":"string"}}},"constructor":{"type":"number"}}}', '[]');
-- ignores other non-objects
SELECT is_jsonb_valid_draft_v7('{"properties":{"__proto__":{"type":"number"},"toString":{"properties":{"length":{"type":"string"}}},"constructor":{"type":"number"}}}', '12');
-- none of the properties mentioned
SELECT is_jsonb_valid_draft_v7('{"properties":{"__proto__":{"type":"number"},"toString":{"properties":{"length":{"type":"string"}}},"constructor":{"type":"number"}}}', '{}');
-- __proto__ not valid
SELECT is_jsonb_valid_draft_v7('{"properties":{"__proto__":{"type":"number"},"toString":{"properties":{"length":{"type":"string"}}},"constructor":{"type":"number"}}}', '{"__proto__":"foo"}');
-- toString not valid
SELECT is_jsonb_valid_draft_v7('{"properties":{"__proto__":{"type":"number"},"toString":{"properties":{"length":{"type":"string"}}},"constructor":{"type":"number"}}}', '{"toString":{"length":37}}');
-- constructor not valid
SELECT is_jsonb_valid_draft_v7('{"properties":{"__proto__":{"type":"number"},"toString":{"properties":{"length":{"type":"string"}}},"constructor":{"type":"number"}}}', '{"constructor":{"length":37}}');
-- all present and valid
SELECT is_jsonb_valid_draft_v7('{"properties":{"__proto__":{"type":"number"},"toString":{"properties":{"length":{"type":"string"}}},"constructor":{"type":"number"}}}', '{"__proto__":12,"toString":{"length":"foo"},"constructor":37}');