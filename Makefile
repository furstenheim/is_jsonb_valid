#PREREQUISITES: prepare_tests
EXTENSION = is_jsonb_valid
DATA = is_jsonb_valid--0.1.3.sql
REGRESS = is_jsonb_valid_test additionalItems additionalProperties allOf anyOf default dependencies enum items maxItems maxLength maxProperties maximum minItems minLength minProperties minimum multipleOf not oneOf pattern patternProperties properties ref required type uniqueItems id infinite additionalItems.v7 additionalProperties.v7 allOf.v7 anyOf.v7 default.v7 dependencies.v7 enum.v7 items.v7 maxItems.v7 maxLength.v7 maxProperties.v7 maximum.v7 minItems.v7 minLength.v7 minProperties.v7 minimum.v7 multipleOf.v7 not.v7 oneOf.v7 pattern.v7 patternProperties.v7 properties.v7 ref.v7 required.v7 type.v7 uniqueItems.v7 id.v7 infinite.v7

MODULES = is_jsonb_valid

# postgres stuff
PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

coverage:
	lcov -d . -c -o lcov.info
	genhtml --show-details --legend --output-directory=coverage --title=PostgreSQL --num-spaces=4 --prefix=./src/ `find . -name lcov.info -print`
