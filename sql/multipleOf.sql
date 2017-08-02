-- by int
-- int by int
SELECT is_jsonb_valid('{"multipleOf":2}', '10');
-- int by int fail
SELECT is_jsonb_valid('{"multipleOf":2}', '7');
-- ignores non-numbers
SELECT is_jsonb_valid('{"multipleOf":2}', '"foo"');
-- by number
-- zero is multiple of anything
SELECT is_jsonb_valid('{"multipleOf":1.5}', '0');
-- 4.5 is multiple of 1.5
SELECT is_jsonb_valid('{"multipleOf":1.5}', '4.5');
-- 35 is not multiple of 1.5
SELECT is_jsonb_valid('{"multipleOf":1.5}', '35');
-- by small number
-- 0.0075 is multiple of 0.0001
SELECT is_jsonb_valid('{"multipleOf":0.0001}', '0.0075');
-- 0.00751 is not multiple of 0.0001
SELECT is_jsonb_valid('{"multipleOf":0.0001}', '0.00751');