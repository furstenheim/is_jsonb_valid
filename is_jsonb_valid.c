#include "postgres.h"
#include "catalog/pg_type.h"
#include "fmgr.h"
#include "utils/builtins.h"
#include "utils/jsonb.h"
PG_MODULE_MAGIC;

/* Taken from src/backend/adt/jsonb_utils.c
 * Compare two jbvString JsonbValue values, a and b.
 *
 * This is a special qsort() comparator used to sort strings in certain
 * internal contexts where it is sufficient to have a well-defined sort order.
 * In particular, object pair keys are sorted according to this criteria to
 * facilitate cheap binary searches where we don't care about lexical sort
 * order.
 *
 * a and b are first sorted based on their length.  If a tie-breaker is
 * required, only then do we consider string binary equality.
 */
static int
lengthCompareJsonbStringValue(const void *a, const void *b)
{
    const JsonbValue *va = (const JsonbValue *) a;
    const JsonbValue *vb = (const JsonbValue *) b;
    int                 res;

    Assert(va->type == jbvString);
    Assert(vb->type == jbvString);

    if (va->val.string.len == vb->val.string.len)
    {
        res = memcmp(va->val.string.val, vb->val.string.val, va->val.string.len);
    }
    else
    {
        res = (va->val.string.len > vb->val.string.len) ? 1 : -1;
    }

    return res;
}

static bool
text_isequal(text *txt1, text *txt2)
{
	return DatumGetBool(DirectFunctionCall2(texteq,
											PointerGetDatum(txt1),
											PointerGetDatum(txt2)));
}


// Taken from jsonb_typeof
static bool check_type (Jsonb * in, char * type)
{
	JsonbIterator *it;
	JsonbValue	v;
	char	   *result;

	if (JB_ROOT_IS_OBJECT(in))
		return strcmp(type, "object") == 0;
	else if (JB_ROOT_IS_ARRAY(in) && !JB_ROOT_IS_SCALAR(in))
		return strcmp(type, "array") == 0;
	else
	{
		Assert(JB_ROOT_IS_SCALAR(in));

		it = JsonbIteratorInit(&in->root);

		/*
		 * A root scalar is stored as an array of one element, so we get the
		 * array and then its first (and only) member.
		 */
		(void) JsonbIteratorNext(&it, &v, true);
		Assert(v.type == jbvArray);
		(void) JsonbIteratorNext(&it, &v, true);
		switch (v.type)
		{
			case jbvNull:
        		return strcmp(type, "null") == 0;
			case jbvString:
				return strcmp(type, "string") == 0;
			case jbvNumeric:
			    if (strcmp(type, "number") == 0) {
			        return true;
			    } else if (strcmp(type, "integer") == 0) {
                    return DatumGetBool(DirectFunctionCall2(
                            numeric_eq,
                            PointerGetDatum((&v)->val.numeric),
                            DirectFunctionCall1(numeric_floor, PointerGetDatum((&v)->val.numeric))));
			    } else {
			        return false;
			    }
			case jbvBool:
				return strcmp(type, "boolean") == 0;
			default:
				elog(ERROR, "unknown jsonb scalar type");
		}
	}
    // TODO maybe free iterators
}



PG_FUNCTION_INFO_V1(is_jsonb_valid);
Datum
is_jsonb_valid(PG_FUNCTION_ARGS)
{
    Jsonb *my_schema = PG_GETARG_JSONB(0);
    Jsonb *my_jsonb = PG_GETARG_JSONB(1);
    JsonbValue propertyKey;
    JsonbValue * propertyValue;
    text* key;
    propertyKey.type = jbvString;
    if (my_schema == NULL)
        ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE), errmsg("Can only sum objects")));
    if (my_jsonb == NULL)
        PG_RETURN_NULL();

    key = cstring_to_text("type");
    propertyKey.val.string.val = VARDATA_ANY(key);
    propertyKey.val.string.len = VARSIZE_ANY_EXHDR(key);

    propertyValue = findJsonbValueFromContainer(&my_schema->root, JB_FOBJECT, &propertyKey);
    if (propertyValue != NULL) {
        if (propertyValue->type != jbvString)
            ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE), errmsg("Type must be string")));
        bool isTypeCorrect = check_type(my_jsonb, propertyValue->val.string.val);
        elog(INFO, isTypeCorrect ? "Type is correct" : "Type is not correct");
    }
    PG_RETURN_BOOL(1 != 2);
}

// elog(INFO, "%d", strcmp(propertyValue->val.string.val, "object"));

