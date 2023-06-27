-- pattern validation
-- a matching pattern is valid
SELECT is_jsonb_valid('{"pattern":"^a*$"}', '"aaa"');
-- a non-matching pattern is invalid
SELECT is_jsonb_valid('{"pattern":"^a*$"}', '"abc"');
-- ignores booleans
SELECT is_jsonb_valid('{"pattern":"^a*$"}', 'true');
-- ignores integers
SELECT is_jsonb_valid('{"pattern":"^a*$"}', '123');
-- ignores floats
SELECT is_jsonb_valid('{"pattern":"^a*$"}', '1');
-- ignores objects
SELECT is_jsonb_valid('{"pattern":"^a*$"}', '{}');
-- ignores arrays
SELECT is_jsonb_valid('{"pattern":"^a*$"}', '[]');
-- ignores null
SELECT is_jsonb_valid('{"pattern":"^a*$"}', 'null');
-- pattern is not anchored
-- matches a substring
SELECT is_jsonb_valid('{"pattern":"a+"}', '"xxaayy"');