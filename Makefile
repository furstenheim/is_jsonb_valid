#PREREQUISITES: prepare_tests
EXTENSION = is_jsonb_valid
DATA = is_jsonb_valid--0.1.3.sql
REGRESS = is_jsonb_valid_test additionalItems additionalItems.v7 additionalProperties additionalProperties.v7 allOf allOf.v7 anyOf anyOf.v7 boolean.v7 const.v7 contains.v7 default default.v7 dependencies dependencies.v7 enum enum.v7 exclusiveMaximum.v7 exclusiveMinimum.v7 id id.v7 if.v7 infinite infinite.v7 items items.v7 maximum maximum.v7 maxItems maxItems.v7 maxLength maxLength.v7 maxProperties maxProperties.v7 minimum minimum.v7 minItems minItems.v7 minLength minLength.v7 minProperties minProperties.v7 multipleOf multipleOf.v7 not not.v7 oneOf oneOf.v7 pattern pattern.v7 patternProperties patternProperties.v7 properties properties.v7 propertyNames.v7 ref ref.v7 required required.v7 type type.v7 uniqueItems uniqueItems.v7 unknownKeyword.v7

MODULES = is_jsonb_valid is_jsonb_valid_draft_v7

# postgres stuff
PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

coverage:
	lcov -d . -c -o lcov.info
	genhtml --show-details --legend --output-directory=coverage --title=PostgreSQL --num-spaces=4 --prefix=./src/ `find . -name lcov.info -print`
