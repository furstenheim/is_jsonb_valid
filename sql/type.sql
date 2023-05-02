-- integer type matches integers
-- an integer is an integer
SELECT is_jsonb_valid('{"type":"integer"}', '1');
-- a float is not an integer
SELECT is_jsonb_valid('{"type":"integer"}', '1.1');
-- a string is not an integer
SELECT is_jsonb_valid('{"type":"integer"}', '"foo"');
-- a string is still not an integer, even if it looks like one
SELECT is_jsonb_valid('{"type":"integer"}', '"1"');
-- an object is not an integer
SELECT is_jsonb_valid('{"type":"integer"}', '{}');
-- an array is not an integer
SELECT is_jsonb_valid('{"type":"integer"}', '[]');
-- a boolean is not an integer
SELECT is_jsonb_valid('{"type":"integer"}', 'true');
-- null is not an integer
SELECT is_jsonb_valid('{"type":"integer"}', 'null');
-- number type matches numbers
-- an integer is a number
SELECT is_jsonb_valid('{"type":"number"}', '1');
-- a float with zero fractional part is a number
SELECT is_jsonb_valid('{"type":"number"}', '1');
-- a float is a number
SELECT is_jsonb_valid('{"type":"number"}', '1.1');
-- a string is not a number
SELECT is_jsonb_valid('{"type":"number"}', '"foo"');
-- a string is still not a number, even if it looks like one
SELECT is_jsonb_valid('{"type":"number"}', '"1"');
-- an object is not a number
SELECT is_jsonb_valid('{"type":"number"}', '{}');
-- an array is not a number
SELECT is_jsonb_valid('{"type":"number"}', '[]');
-- a boolean is not a number
SELECT is_jsonb_valid('{"type":"number"}', 'true');
-- null is not a number
SELECT is_jsonb_valid('{"type":"number"}', 'null');
-- string type matches strings
-- 1 is not a string
SELECT is_jsonb_valid('{"type":"string"}', '1');
-- a float is not a string
SELECT is_jsonb_valid('{"type":"string"}', '1.1');
-- a string is a string
SELECT is_jsonb_valid('{"type":"string"}', '"foo"');
-- a string is still a string, even if it looks like a number
SELECT is_jsonb_valid('{"type":"string"}', '"1"');
-- an empty string is still a string
SELECT is_jsonb_valid('{"type":"string"}', '""');
-- an object is not a string
SELECT is_jsonb_valid('{"type":"string"}', '{}');
-- an array is not a string
SELECT is_jsonb_valid('{"type":"string"}', '[]');
-- a boolean is not a string
SELECT is_jsonb_valid('{"type":"string"}', 'true');
-- null is not a string
SELECT is_jsonb_valid('{"type":"string"}', 'null');
-- object type matches objects
-- an integer is not an object
SELECT is_jsonb_valid('{"type":"object"}', '1');
-- a float is not an object
SELECT is_jsonb_valid('{"type":"object"}', '1.1');
-- a string is not an object
SELECT is_jsonb_valid('{"type":"object"}', '"foo"');
-- an object is an object
SELECT is_jsonb_valid('{"type":"object"}', '{}');
-- an array is not an object
SELECT is_jsonb_valid('{"type":"object"}', '[]');
-- a boolean is not an object
SELECT is_jsonb_valid('{"type":"object"}', 'true');
-- null is not an object
SELECT is_jsonb_valid('{"type":"object"}', 'null');
-- array type matches arrays
-- an integer is not an array
SELECT is_jsonb_valid('{"type":"array"}', '1');
-- a float is not an array
SELECT is_jsonb_valid('{"type":"array"}', '1.1');
-- a string is not an array
SELECT is_jsonb_valid('{"type":"array"}', '"foo"');
-- an object is not an array
SELECT is_jsonb_valid('{"type":"array"}', '{}');
-- an array is an array
SELECT is_jsonb_valid('{"type":"array"}', '[]');
-- a boolean is not an array
SELECT is_jsonb_valid('{"type":"array"}', 'true');
-- null is not an array
SELECT is_jsonb_valid('{"type":"array"}', 'null');
-- boolean type matches booleans
-- an integer is not a boolean
SELECT is_jsonb_valid('{"type":"boolean"}', '1');
-- zero is not a boolean
SELECT is_jsonb_valid('{"type":"boolean"}', '0');
-- a float is not a boolean
SELECT is_jsonb_valid('{"type":"boolean"}', '1.1');
-- a string is not a boolean
SELECT is_jsonb_valid('{"type":"boolean"}', '"foo"');
-- an empty string is not a boolean
SELECT is_jsonb_valid('{"type":"boolean"}', '""');
-- an object is not a boolean
SELECT is_jsonb_valid('{"type":"boolean"}', '{}');
-- an array is not a boolean
SELECT is_jsonb_valid('{"type":"boolean"}', '[]');
-- true is a boolean
SELECT is_jsonb_valid('{"type":"boolean"}', 'true');
-- false is a boolean
SELECT is_jsonb_valid('{"type":"boolean"}', 'false');
-- null is not a boolean
SELECT is_jsonb_valid('{"type":"boolean"}', 'null');
-- null type matches only the null object
-- an integer is not null
SELECT is_jsonb_valid('{"type":"null"}', '1');
-- a float is not null
SELECT is_jsonb_valid('{"type":"null"}', '1.1');
-- zero is not null
SELECT is_jsonb_valid('{"type":"null"}', '0');
-- a string is not null
SELECT is_jsonb_valid('{"type":"null"}', '"foo"');
-- an empty string is not null
SELECT is_jsonb_valid('{"type":"null"}', '""');
-- an object is not null
SELECT is_jsonb_valid('{"type":"null"}', '{}');
-- an array is not null
SELECT is_jsonb_valid('{"type":"null"}', '[]');
-- true is not null
SELECT is_jsonb_valid('{"type":"null"}', 'true');
-- false is not null
SELECT is_jsonb_valid('{"type":"null"}', 'false');
-- null is null
SELECT is_jsonb_valid('{"type":"null"}', 'null');
-- multiple types can be specified in an array
-- an integer is valid
SELECT is_jsonb_valid('{"type":["integer","string"]}', '1');
-- a string is valid
SELECT is_jsonb_valid('{"type":["integer","string"]}', '"foo"');
-- a float is invalid
SELECT is_jsonb_valid('{"type":["integer","string"]}', '1.1');
-- an object is invalid
SELECT is_jsonb_valid('{"type":["integer","string"]}', '{}');
-- an array is invalid
SELECT is_jsonb_valid('{"type":["integer","string"]}', '[]');
-- a boolean is invalid
SELECT is_jsonb_valid('{"type":["integer","string"]}', 'true');
-- null is invalid
SELECT is_jsonb_valid('{"type":["integer","string"]}', 'null');
-- type as array with one item
-- string is valid
SELECT is_jsonb_valid('{"type":["string"]}', '"foo"');
-- number is invalid
SELECT is_jsonb_valid('{"type":["string"]}', '123');
-- type: array or object
-- array is valid
SELECT is_jsonb_valid('{"type":["array","object"]}', '[1,2,3]');
-- object is valid
SELECT is_jsonb_valid('{"type":["array","object"]}', '{"foo":123}');
-- number is invalid
SELECT is_jsonb_valid('{"type":["array","object"]}', '123');
-- string is invalid
SELECT is_jsonb_valid('{"type":["array","object"]}', '"foo"');
-- null is invalid
SELECT is_jsonb_valid('{"type":["array","object"]}', 'null');
-- type: array, object or null
-- array is valid
SELECT is_jsonb_valid('{"type":["array","object","null"]}', '[1,2,3]');
-- object is valid
SELECT is_jsonb_valid('{"type":["array","object","null"]}', '{"foo":123}');
-- null is valid
SELECT is_jsonb_valid('{"type":["array","object","null"]}', 'null');
-- number is invalid
SELECT is_jsonb_valid('{"type":["array","object","null"]}', '123');
-- string is invalid
SELECT is_jsonb_valid('{"type":["array","object","null"]}', '"foo"');