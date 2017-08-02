-- object properties validation
-- both properties present and valid is valid
SELECT is_jsonb_valid('{"properties":{"foo":{"type":"integer"},"bar":{"type":"string"}}}', '{"foo":1,"bar":"baz"}');
-- one property invalid is invalid
SELECT is_jsonb_valid('{"properties":{"foo":{"type":"integer"},"bar":{"type":"string"}}}', '{"foo":1,"bar":{}}');
-- both properties invalid is invalid
SELECT is_jsonb_valid('{"properties":{"foo":{"type":"integer"},"bar":{"type":"string"}}}', '{"foo":[],"bar":{}}');
-- doesn't invalidate other properties
SELECT is_jsonb_valid('{"properties":{"foo":{"type":"integer"},"bar":{"type":"string"}}}', '{"quux":[]}');
-- ignores arrays
SELECT is_jsonb_valid('{"properties":{"foo":{"type":"integer"},"bar":{"type":"string"}}}', '[]');
-- ignores other non-objects
SELECT is_jsonb_valid('{"properties":{"foo":{"type":"integer"},"bar":{"type":"string"}}}', '12');
-- properties, patternProperties, additionalProperties interaction
-- property validates property
SELECT is_jsonb_valid('{"properties":{"foo":{"type":"array","maxItems":3},"bar":{"type":"array"}},"patternProperties":{"f.o":{"minItems":2}},"additionalProperties":{"type":"integer"}}', '{"foo":[1,2]}');
-- property invalidates property
SELECT is_jsonb_valid('{"properties":{"foo":{"type":"array","maxItems":3},"bar":{"type":"array"}},"patternProperties":{"f.o":{"minItems":2}},"additionalProperties":{"type":"integer"}}', '{"foo":[1,2,3,4]}');
-- patternProperty invalidates property
SELECT is_jsonb_valid('{"properties":{"foo":{"type":"array","maxItems":3},"bar":{"type":"array"}},"patternProperties":{"f.o":{"minItems":2}},"additionalProperties":{"type":"integer"}}', '{"foo":[]}');
-- patternProperty validates nonproperty
SELECT is_jsonb_valid('{"properties":{"foo":{"type":"array","maxItems":3},"bar":{"type":"array"}},"patternProperties":{"f.o":{"minItems":2}},"additionalProperties":{"type":"integer"}}', '{"fxo":[1,2]}');
-- patternProperty invalidates nonproperty
SELECT is_jsonb_valid('{"properties":{"foo":{"type":"array","maxItems":3},"bar":{"type":"array"}},"patternProperties":{"f.o":{"minItems":2}},"additionalProperties":{"type":"integer"}}', '{"fxo":[]}');
-- additionalProperty ignores property
SELECT is_jsonb_valid('{"properties":{"foo":{"type":"array","maxItems":3},"bar":{"type":"array"}},"patternProperties":{"f.o":{"minItems":2}},"additionalProperties":{"type":"integer"}}', '{"bar":[]}');
-- additionalProperty validates others
SELECT is_jsonb_valid('{"properties":{"foo":{"type":"array","maxItems":3},"bar":{"type":"array"}},"patternProperties":{"f.o":{"minItems":2}},"additionalProperties":{"type":"integer"}}', '{"quux":3}');
-- additionalProperty invalidates others
SELECT is_jsonb_valid('{"properties":{"foo":{"type":"array","maxItems":3},"bar":{"type":"array"}},"patternProperties":{"f.o":{"minItems":2}},"additionalProperties":{"type":"integer"}}', '{"quux":"foo"}');