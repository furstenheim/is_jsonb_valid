-- pattern validation
-- a matching pattern is valid
SELECT is_jsonb_valid('{"pattern":"^a*$"}', '"aaa"');
-- a non-matching pattern is invalid
SELECT is_jsonb_valid('{"pattern":"^a*$"}', '"abc"');
-- ignores non-strings
SELECT is_jsonb_valid('{"pattern":"^a*$"}', 'true');
-- pattern is not anchored
-- matches a substring
SELECT is_jsonb_valid('{"pattern":"a+"}', '"xxaayy"');