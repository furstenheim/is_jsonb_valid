-- patternProperties validates properties matching a regex
-- a single valid match is valid
SELECT is_jsonb_valid('{"patternProperties":{"f.*o":{"type":"integer"}}}', '{"foo":1}');
-- multiple valid matches is valid
SELECT is_jsonb_valid('{"patternProperties":{"f.*o":{"type":"integer"}}}', '{"foo":1,"foooooo":2}');
-- a single invalid match is invalid
SELECT is_jsonb_valid('{"patternProperties":{"f.*o":{"type":"integer"}}}', '{"foo":"bar","fooooo":2}');
-- multiple invalid matches is invalid
SELECT is_jsonb_valid('{"patternProperties":{"f.*o":{"type":"integer"}}}', '{"foo":"bar","foooooo":"baz"}');
-- ignores arrays
SELECT is_jsonb_valid('{"patternProperties":{"f.*o":{"type":"integer"}}}', '[]');
-- ignores strings
SELECT is_jsonb_valid('{"patternProperties":{"f.*o":{"type":"integer"}}}', '""');
-- ignores other non-objects
SELECT is_jsonb_valid('{"patternProperties":{"f.*o":{"type":"integer"}}}', '12');
-- multiple simultaneous patternProperties are validated
-- a single valid match is valid
SELECT is_jsonb_valid('{"patternProperties":{"a*":{"type":"integer"},"aaa*":{"maximum":20}}}', '{"a":21}');
-- a simultaneous match is valid
SELECT is_jsonb_valid('{"patternProperties":{"a*":{"type":"integer"},"aaa*":{"maximum":20}}}', '{"aaaa":18}');
-- multiple matches is valid
SELECT is_jsonb_valid('{"patternProperties":{"a*":{"type":"integer"},"aaa*":{"maximum":20}}}', '{"a":21,"aaaa":18}');
-- an invalid due to one is invalid
SELECT is_jsonb_valid('{"patternProperties":{"a*":{"type":"integer"},"aaa*":{"maximum":20}}}', '{"a":"bar"}');
-- an invalid due to the other is invalid
SELECT is_jsonb_valid('{"patternProperties":{"a*":{"type":"integer"},"aaa*":{"maximum":20}}}', '{"aaaa":31}');
-- an invalid due to both is invalid
SELECT is_jsonb_valid('{"patternProperties":{"a*":{"type":"integer"},"aaa*":{"maximum":20}}}', '{"aaa":"foo","aaaa":31}');
-- regexes are not anchored by default and are case sensitive
-- non recognized members are ignored
SELECT is_jsonb_valid('{"patternProperties":{"[0-9]{2,}":{"type":"boolean"},"X_":{"type":"string"}}}', '{"answer 1":"42"}');
-- recognized members are accounted for
SELECT is_jsonb_valid('{"patternProperties":{"[0-9]{2,}":{"type":"boolean"},"X_":{"type":"string"}}}', '{"a31b":null}');
-- regexes are case sensitive
SELECT is_jsonb_valid('{"patternProperties":{"[0-9]{2,}":{"type":"boolean"},"X_":{"type":"string"}}}', '{"a_x_3":3}');
-- regexes are case sensitive, 2
SELECT is_jsonb_valid('{"patternProperties":{"[0-9]{2,}":{"type":"boolean"},"X_":{"type":"string"}}}', '{"a_X_3":3}');