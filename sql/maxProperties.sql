-- maxProperties validation
-- shorter is valid
SELECT is_jsonb_valid('{"maxProperties":2}', '{"foo":1}');
-- exact length is valid
SELECT is_jsonb_valid('{"maxProperties":2}', '{"foo":1,"bar":2}');
-- too long is invalid
SELECT is_jsonb_valid('{"maxProperties":2}', '{"foo":1,"bar":2,"baz":3}');
-- ignores arrays
SELECT is_jsonb_valid('{"maxProperties":2}', '[1,2,3]');
-- ignores strings
SELECT is_jsonb_valid('{"maxProperties":2}', '"foobar"');
-- ignores other non-objects
SELECT is_jsonb_valid('{"maxProperties":2}', '12');