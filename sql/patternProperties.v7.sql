-- patternProperties validates properties matching a regex
-- a single valid match is valid
SELECT is_jsonb_valid_draft_v7('{"patternProperties":{"f.*o":{"type":"integer"}}}', '{"foo":1}');
-- multiple valid matches is valid
SELECT is_jsonb_valid_draft_v7('{"patternProperties":{"f.*o":{"type":"integer"}}}', '{"foo":1,"foooooo":2}');
-- a single invalid match is invalid
SELECT is_jsonb_valid_draft_v7('{"patternProperties":{"f.*o":{"type":"integer"}}}', '{"foo":"bar","fooooo":2}');
-- multiple invalid matches is invalid
SELECT is_jsonb_valid_draft_v7('{"patternProperties":{"f.*o":{"type":"integer"}}}', '{"foo":"bar","foooooo":"baz"}');
-- ignores arrays
SELECT is_jsonb_valid_draft_v7('{"patternProperties":{"f.*o":{"type":"integer"}}}', '["foo"]');
-- ignores strings
SELECT is_jsonb_valid_draft_v7('{"patternProperties":{"f.*o":{"type":"integer"}}}', '"foo"');
-- ignores other non-objects
SELECT is_jsonb_valid_draft_v7('{"patternProperties":{"f.*o":{"type":"integer"}}}', '12');
-- multiple simultaneous patternProperties are validated
-- a single valid match is valid
SELECT is_jsonb_valid_draft_v7('{"patternProperties":{"a*":{"type":"integer"},"aaa*":{"maximum":20}}}', '{"a":21}');
-- a simultaneous match is valid
SELECT is_jsonb_valid_draft_v7('{"patternProperties":{"a*":{"type":"integer"},"aaa*":{"maximum":20}}}', '{"aaaa":18}');
-- multiple matches is valid
SELECT is_jsonb_valid_draft_v7('{"patternProperties":{"a*":{"type":"integer"},"aaa*":{"maximum":20}}}', '{"a":21,"aaaa":18}');
-- an invalid due to one is invalid
SELECT is_jsonb_valid_draft_v7('{"patternProperties":{"a*":{"type":"integer"},"aaa*":{"maximum":20}}}', '{"a":"bar"}');
-- an invalid due to the other is invalid
SELECT is_jsonb_valid_draft_v7('{"patternProperties":{"a*":{"type":"integer"},"aaa*":{"maximum":20}}}', '{"aaaa":31}');
-- an invalid due to both is invalid
SELECT is_jsonb_valid_draft_v7('{"patternProperties":{"a*":{"type":"integer"},"aaa*":{"maximum":20}}}', '{"aaa":"foo","aaaa":31}');
-- regexes are not anchored by default and are case sensitive
-- non recognized members are ignored
SELECT is_jsonb_valid_draft_v7('{"patternProperties":{"[0-9]{2,}":{"type":"boolean"},"X_":{"type":"string"}}}', '{"answer 1":"42"}');
-- recognized members are accounted for
SELECT is_jsonb_valid_draft_v7('{"patternProperties":{"[0-9]{2,}":{"type":"boolean"},"X_":{"type":"string"}}}', '{"a31b":null}');
-- regexes are case sensitive
SELECT is_jsonb_valid_draft_v7('{"patternProperties":{"[0-9]{2,}":{"type":"boolean"},"X_":{"type":"string"}}}', '{"a_x_3":3}');
-- regexes are case sensitive, 2
SELECT is_jsonb_valid_draft_v7('{"patternProperties":{"[0-9]{2,}":{"type":"boolean"},"X_":{"type":"string"}}}', '{"a_X_3":3}');
-- patternProperties with boolean schemas
-- object with property matching schema true is valid
SELECT is_jsonb_valid_draft_v7('{"patternProperties":{"f.*":true,"b.*":false}}', '{"foo":1}');
-- object with property matching schema false is invalid
SELECT is_jsonb_valid_draft_v7('{"patternProperties":{"f.*":true,"b.*":false}}', '{"bar":2}');
-- object with both properties is invalid
SELECT is_jsonb_valid_draft_v7('{"patternProperties":{"f.*":true,"b.*":false}}', '{"foo":1,"bar":2}');
-- object with a property matching both true and false is invalid
SELECT is_jsonb_valid_draft_v7('{"patternProperties":{"f.*":true,"b.*":false}}', '{"foobar":1}');
-- empty object is valid
SELECT is_jsonb_valid_draft_v7('{"patternProperties":{"f.*":true,"b.*":false}}', '{}');
-- patternProperties with null valued instance properties
-- allows null values
SELECT is_jsonb_valid_draft_v7('{"patternProperties":{"^.*bar$":{"type":"null"}}}', '{"foobar":null}');