#PREREQUISITES: prepare_tests
EXTENSION = is_jsonb_valid
DATA = is_jsonb_valid--0.1.1.sql
REGRESS = is_jsonb_valid_test additionalItems additionalProperties allOf anyOf default dependencies enum items maxItems maxLength maxProperties maximum minItems minLength minProperties minimum multipleOf not oneOf pattern patternProperties properties ref required type uniqueItems
MODULES = is_jsonb_valid

# postgres stuff
PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)


coverage: 
	lcov -d . -c -o lcov.info
	genhtml --show-details --legend --output-directory=coverage --title=PostgreSQL --num-spaces=4 --prefix=./src/ `find . -name lcov.info -print`