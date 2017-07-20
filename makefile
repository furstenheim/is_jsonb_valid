##prepare_tests:
##    echo '1'

#PREREQUISITES: prepare_tests
EXTENSION = is_jsonb_valid
DATA = is_jsonb_valid--0.0.1.sql
#REGRESS = 

# postgres stuff
PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
