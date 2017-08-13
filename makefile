##prepare_tests:
##    echo '1'

#PREREQUISITES: prepare_tests
EXTENSION = is_jsonb_valid
DATA = is_jsonb_valid--0.0.1.sql
REGRESS = is_jsonb_valid_test additionalItems additionalProperties allOf anyOf default dependencies enum items maxItems maxLength maxProperties maximum minItems minLength minProperties minimum multipleOf not oneOf pattern patternProperties properties ref required type uniqueItems
MODULES = is_jsonb_valid

# postgres stuff
PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
