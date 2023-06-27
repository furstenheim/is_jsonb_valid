-- by int
-- int by int
SELECT is_jsonb_valid_draft_v7('{"multipleOf":2}', '10');
-- int by int fail
SELECT is_jsonb_valid_draft_v7('{"multipleOf":2}', '7');
-- ignores non-numbers
SELECT is_jsonb_valid_draft_v7('{"multipleOf":2}', '"foo"');
-- by number
-- zero is multiple of anything
SELECT is_jsonb_valid_draft_v7('{"multipleOf":1.5}', '0');
-- 4.5 is multiple of 1.5
SELECT is_jsonb_valid_draft_v7('{"multipleOf":1.5}', '4.5');
-- 35 is not multiple of 1.5
SELECT is_jsonb_valid_draft_v7('{"multipleOf":1.5}', '35');
-- by small number
-- 0.0075 is multiple of 0.0001
SELECT is_jsonb_valid_draft_v7('{"multipleOf":0.0001}', '0.0075');
-- 0.00751 is not multiple of 0.0001
SELECT is_jsonb_valid_draft_v7('{"multipleOf":0.0001}', '0.00751');
-- float division = inf
-- always invalid, but naive implementations may raise an overflow error
SELECT is_jsonb_valid_draft_v7('{"type":"integer","multipleOf":0.123456789}', '1e+308');
-- small multiple of large integer
-- any integer is a multiple of 1e-8
SELECT is_jsonb_valid_draft_v7('{"type":"integer","multipleOf":1e-8}', '12391239123');