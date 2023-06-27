-- ignore if without then or else
-- valid when valid against lone if
SELECT is_jsonb_valid_draft_v7('{"if":{"const":0}}', '0');
-- valid when invalid against lone if
SELECT is_jsonb_valid_draft_v7('{"if":{"const":0}}', '"hello"');
-- ignore then without if
-- valid when valid against lone then
SELECT is_jsonb_valid_draft_v7('{"then":{"const":0}}', '0');
-- valid when invalid against lone then
SELECT is_jsonb_valid_draft_v7('{"then":{"const":0}}', '"hello"');
-- ignore else without if
-- valid when valid against lone else
SELECT is_jsonb_valid_draft_v7('{"else":{"const":0}}', '0');
-- valid when invalid against lone else
SELECT is_jsonb_valid_draft_v7('{"else":{"const":0}}', '"hello"');
-- if and then without else
-- valid through then
SELECT is_jsonb_valid_draft_v7('{"if":{"exclusiveMaximum":0},"then":{"minimum":-10}}', '-1');
-- invalid through then
SELECT is_jsonb_valid_draft_v7('{"if":{"exclusiveMaximum":0},"then":{"minimum":-10}}', '-100');
-- valid when if test fails
SELECT is_jsonb_valid_draft_v7('{"if":{"exclusiveMaximum":0},"then":{"minimum":-10}}', '3');
-- if and else without then
-- valid when if test passes
SELECT is_jsonb_valid_draft_v7('{"if":{"exclusiveMaximum":0},"else":{"multipleOf":2}}', '-1');
-- valid through else
SELECT is_jsonb_valid_draft_v7('{"if":{"exclusiveMaximum":0},"else":{"multipleOf":2}}', '4');
-- invalid through else
SELECT is_jsonb_valid_draft_v7('{"if":{"exclusiveMaximum":0},"else":{"multipleOf":2}}', '3');
-- validate against correct branch, then vs else
-- valid through then
SELECT is_jsonb_valid_draft_v7('{"if":{"exclusiveMaximum":0},"then":{"minimum":-10},"else":{"multipleOf":2}}', '-1');
-- invalid through then
SELECT is_jsonb_valid_draft_v7('{"if":{"exclusiveMaximum":0},"then":{"minimum":-10},"else":{"multipleOf":2}}', '-100');
-- valid through else
SELECT is_jsonb_valid_draft_v7('{"if":{"exclusiveMaximum":0},"then":{"minimum":-10},"else":{"multipleOf":2}}', '4');
-- invalid through else
SELECT is_jsonb_valid_draft_v7('{"if":{"exclusiveMaximum":0},"then":{"minimum":-10},"else":{"multipleOf":2}}', '3');
-- non-interference across combined schemas
-- valid, but would have been invalid through then
SELECT is_jsonb_valid_draft_v7('{"allOf":[{"if":{"exclusiveMaximum":0}},{"then":{"minimum":-10}},{"else":{"multipleOf":2}}]}', '-100');
-- valid, but would have been invalid through else
SELECT is_jsonb_valid_draft_v7('{"allOf":[{"if":{"exclusiveMaximum":0}},{"then":{"minimum":-10}},{"else":{"multipleOf":2}}]}', '3');
-- if with boolean schema true
-- boolean schema true in if always chooses the then path (valid)
SELECT is_jsonb_valid_draft_v7('{"if":true,"then":{"const":"then"},"else":{"const":"else"}}', '"then"');
-- boolean schema true in if always chooses the then path (invalid)
SELECT is_jsonb_valid_draft_v7('{"if":true,"then":{"const":"then"},"else":{"const":"else"}}', '"else"');
-- if with boolean schema false
-- boolean schema false in if always chooses the else path (invalid)
SELECT is_jsonb_valid_draft_v7('{"if":false,"then":{"const":"then"},"else":{"const":"else"}}', '"then"');
-- boolean schema false in if always chooses the else path (valid)
SELECT is_jsonb_valid_draft_v7('{"if":false,"then":{"const":"then"},"else":{"const":"else"}}', '"else"');
-- if appears at the end when serialized (keyword processing sequence)
-- yes redirects to then and passes
SELECT is_jsonb_valid_draft_v7('{"then":{"const":"yes"},"else":{"const":"other"},"if":{"maxLength":4}}', '"yes"');
-- other redirects to else and passes
SELECT is_jsonb_valid_draft_v7('{"then":{"const":"yes"},"else":{"const":"other"},"if":{"maxLength":4}}', '"other"');
-- no redirects to then and fails
SELECT is_jsonb_valid_draft_v7('{"then":{"const":"yes"},"else":{"const":"other"},"if":{"maxLength":4}}', '"no"');
-- invalid redirects to else and fails
SELECT is_jsonb_valid_draft_v7('{"then":{"const":"yes"},"else":{"const":"other"},"if":{"maxLength":4}}', '"invalid"');