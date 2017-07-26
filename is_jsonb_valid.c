#include "postgres.h"
#include "catalog/pg_type.h"
#include "fmgr.h"
#include "utils/builtins.h"
#include "utils/jsonb.h"
PG_MODULE_MAGIC;

//static bool _is_jsonb_valid (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema);

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
static bool check_type (Jsonb * in, char * type, int typeLen)
{
	JsonbIterator *it;
	JsonbValue	v;

	if (JB_ROOT_IS_OBJECT(in))
		return strncmp(type, "object", typeLen) == 0;
	else if (JB_ROOT_IS_ARRAY(in) && !JB_ROOT_IS_SCALAR(in))
		return strncmp(type, "array", typeLen) == 0;
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
        		return strncmp(type, "null", typeLen) == 0;
			case jbvString:
				return strncmp(type, "string", typeLen) == 0;
			case jbvNumeric:
			    if (strncmp(type, "number", typeLen) == 0) {
			        return true;
			    } else if (strncmp(type, "integer", typeLen) == 0) {
                    return DatumGetBool(DirectFunctionCall2(
                            numeric_eq,
                            PointerGetDatum((&v)->val.numeric),
                            DirectFunctionCall1(numeric_floor, PointerGetDatum((&v)->val.numeric))));
			    } else {
			        return false;
			    }
			case jbvBool:
				return strncmp(type, "boolean", typeLen) == 0;
			default:
				elog(ERROR, "unknown jsonb scalar type");
		}
	}
    // TODO maybe free iterators
}
// TODO rename my_jsonb to data
static bool _is_jsonb_valid (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema)
{
    JsonbValue propertyKey;
    JsonbValue * propertyValue;
    JsonbValue myJsonData;
    text* key;
    propertyKey.type = jbvString;
    bool isValid = true;
    if (schemaJb == NULL)
        ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE), errmsg("Can only sum objects")));
    if (dataJb == NULL)
        // TODO check required
        return true;

    // type
    key = cstring_to_text("type");
    propertyKey.val.string.val = VARDATA_ANY(key);
    propertyKey.val.string.len = VARSIZE_ANY_EXHDR(key);

    propertyValue = findJsonbValueFromContainer(&schemaJb->root, JB_FOBJECT, &propertyKey);

    if (propertyValue != NULL) {
        bool isTypeCorrect;
    // TODO accept arrays of types
        if (propertyValue->type != jbvString)
            ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE), errmsg("Type must be string")));
        isTypeCorrect = check_type(dataJb, propertyValue->val.string.val, propertyValue->val.string.len);
        isValid = isValid && isTypeCorrect;
        elog(INFO, isTypeCorrect ? "Type is correct" : "Type is not correct");
    }

    // properties
    key = cstring_to_text("properties");
    propertyKey.val.string.val = VARDATA_ANY(key);
    propertyKey.val.string.len = VARSIZE_ANY_EXHDR(key);

    propertyValue = findJsonbValueFromContainer(&schemaJb->root, JB_FOBJECT, &propertyKey);
    if (propertyValue != NULL) {
            bool isTypeCorrect;
            Jsonb * propertiesObject;
            JsonbIterator * it;
            JsonbIteratorToken r;
            JsonbValue keyJbv, subSchemaJbv;
            if (propertyValue->type != jbvBinary)
                ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE), errmsg("Properties must be an object")));
            propertiesObject = JsonbValueToJsonb(propertyValue);
            Assert(JB_ROOT_IS_OBJECT(propertiesObject));
            elog(INFO, "There are properties to check");

            it = JsonbIteratorInit(&propertiesObject->root);
            r = JsonbIteratorNext(&it, &keyJbv, true);
            Assert(r == WJB_BEGIN_OBJECT);

            while (true) {
                Jsonb * subSchemaJb, *subDataJb;
                JsonbValue *subDataJbv;
                bool isPropertyValid;
                r = JsonbIteratorNext(&it, &keyJbv, true);
                if (r == WJB_END_OBJECT)
                    break;
                r = JsonbIteratorNext(&it, &subSchemaJbv, true);
                subDataJbv = findJsonbValueFromContainer(&dataJb->root, JB_FOBJECT, &keyJbv);
                subDataJb = subDataJbv == NULL ? NULL : JsonbValueToJsonb(subDataJbv);
                subSchemaJb = JsonbValueToJsonb(&subSchemaJbv);
                isPropertyValid = _is_jsonb_valid(subSchemaJb, subDataJb, root_schema);
                elog(INFO, isPropertyValid ? "Property is valid": "Property is not valid");
                isValid = isValid && isPropertyValid;
            }


    }

    return isValid;
}

PG_FUNCTION_INFO_V1(is_jsonb_valid);
Datum
is_jsonb_valid(PG_FUNCTION_ARGS)
{
    Jsonb *my_schema = PG_GETARG_JSONB(0);
    Jsonb *my_jsonb = PG_GETARG_JSONB(1);
    bool is_valid = _is_jsonb_valid(my_schema, my_jsonb, my_schema);
    PG_RETURN_BOOL(is_valid);
}

PG_FUNCTION_INFO_V1(jsonb_get2);
Datum
jsonb_get2(PG_FUNCTION_ARGS)
{
    Jsonb *jb = PG_GETARG_JSONB(0);
    text * key;
    JsonbValue propertyKey;
    JsonbValue * propertyValue;

    propertyKey.type = jbvString;
    key = cstring_to_text("a");
    propertyKey.val.string.val = VARDATA_ANY(key);
    propertyKey.val.string.len = VARSIZE_ANY_EXHDR(key);

    propertyValue = findJsonbValueFromContainer(&jb->root, JB_FOBJECT, &propertyKey);
    elog(INFO, propertyValue->type == jbvObject ? "element is object" : "Element is not object");
    elog(INFO, propertyValue->type == jbvBinary ? "element is binary" : "Element is not binary");
    PG_RETURN_JSONB(JsonbValueToJsonb(propertyValue));
}

// elog(INFO, "%d", strcmp(propertyValue->val.string.val, "object"));

