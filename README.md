## Is jsonb valid
![Build Status](https://travis-ci.org/furstenheim/is_jsonb_valid.svg?branch=master)


is_jsonb_valid is a native PostgreSQL extension to validate json schemas following [Draft4](https://tools.ietf.org/html/draft-zyp-json-schema-04).
The extension exposes only one function `is_jsonb_valid(schema jsonb, data jsonb)` which returns a boolean depending 
on the success of the validation.

Examples:

    SELECT is_jsonb_valid('{"type": "number"}', '1');
    > t
    SELECT is_jsonb_valid('{"type": "object"}', '1');
    > f

It passes (most of) [JSON-Schema-Test-Suite](https://github.com/json-schema-org/JSON-Schema-Test-Suite). The exceptions are:
* $refRemote has been removed for obvious reasons.
* $ref support is limited to references nested at root, that is, something like `"$ref": "#/definitions/myschema"`. In particular, it doesn't check for `"$id"` in the chain to the root, and it doesn't support remote refs.
* format is not supported (this is optional in the draft).

### Testing and Installation

Make sure that you have PostgreSQL 9.6 or newer (check ci.yml for supported versions). In the directory of the project do:

    make install && make installcheck
    
This will compile the extension and run the tests. Later in psql run:

    CREATE EXTENSION is_jsonb_valid;

You can also run tests without installing postgres.

```
 rm -f is_jsonb_valid.o is_jsonb_valid.bc && docker run -it --rm --mount "type=bind,src=$(pwd),dst=/repo" pgxn/pgxn-tools     sh -c 'cd /repo && make clean && pg-start 12 && pg-build-test'  >log 2>&1

```

### Benchmarking

Benchmarking is always tricky, I've tried to check against a real world example, in particular tweets.
The only other extension that I know for this purpose is [postgres-json-schema](https://github.com/gavinwahl/postgres-json-schema/blob/master/postgres-json-schema--0.1.0.sql).
For more information on how to run the benchmarks check `./tools/README.md`

| Numbers of tweets | is_jsonb_valid (ms) |  postgres-json-schema (ms) | Improvement (times)
| --------------- | ---------------- | --------------- | ------- |
| 10       |  34.270  | 192.678 |  5.6 |
| 100 | 206.378 |  1975.543 | 9.6
| 10000 | 8911.354 | 203172.464 | 22.8


### Disclaimer
This project is a based on postgres-json-schema. It has been written from scratch in C (original was written in SQL).


