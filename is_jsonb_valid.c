#include "postgres.h"
#include "catalog/pg_type.h"
#include "fmgr.h"
#include "utils/builtins.h"
#include "utils/jsonb.h"
PG_MODULE_MAGIC;

static bool _is_jsonb_valid (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema);

static JsonbValue * get_jbv_from_key (Jsonb * in, const char * key);

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
                            PointerGetDatum(v.val.numeric),
                            DirectFunctionCall1(numeric_floor, PointerGetDatum(v.val.numeric))));
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

static bool check_properties (Jsonb * dataJb, JsonbValue * propertyValue, Jsonb * root_schema) {
        bool isValid = true;
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
        return isValid;
}

static bool check_items (Jsonb * dataJb, JsonbValue * itemsValue, JsonbValue * additionalItemsJbv, Jsonb * root_schema) {
    bool isValid = true;
    Jsonb * itemsObject;
    JsonbIterator * it;
    JsonbIteratorToken r;
    JsonbValue itemJbv;
    if (!JB_ROOT_IS_ARRAY(dataJb)) return isValid;

    itemsObject = JsonbValueToJsonb(itemsValue);

    if (JB_ROOT_IS_OBJECT(itemsObject)) {
        it = JsonbIteratorInit(&dataJb->root);
        r = JsonbIteratorNext(&it, &itemJbv, true);
        Assert(r == WJB_BEGIN_ARRAY);
        while (isValid) {
            Jsonb * subDataJb;
            bool isItemValid;
            r = JsonbIteratorNext(&it, &itemJbv, true);

            if (r == WJB_END_ARRAY) {
                break;
            }
            subDataJb = JsonbValueToJsonb(&itemJbv);
            isItemValid = _is_jsonb_valid(itemsObject, subDataJb, root_schema);
            elog(INFO, isItemValid ? "Item is valid" : "Item is not valid");
            isValid = isValid && isItemValid;
        }
    } else if (JB_ROOT_IS_ARRAY(itemsObject)) {
        JsonbIterator *schemaIt;
        JsonbIteratorToken schemaR;
        JsonbValue schemaJbv;
        Jsonb * additionalItemsJb;
        bool additionalItemsBuilt = false;
        bool isItemsObjectFinished = false;
        it = JsonbIteratorInit(&dataJb->root);
        r = JsonbIteratorNext(&it, &itemJbv, true);

        schemaIt = JsonbIteratorInit(&itemsObject->root);
        schemaR = JsonbIteratorNext(&schemaIt, &schemaJbv, true);

        Assert(r == WJB_BEGIN_ARRAY);
        Assert(schemaR == WJB_BEGIN_ARRAY);

        while (isValid) {
            bool isItemValid;
            r = JsonbIteratorNext(&it, &itemJbv, true);
            if (!isItemsObjectFinished)
                schemaR = JsonbIteratorNext(&schemaIt, &schemaJbv, true);
                if (schemaR == WJB_END_ARRAY)
                    isItemsObjectFinished = true;
                if (r == WJB_END_ARRAY) {
                    break;
                }
                if (!isItemsObjectFinished) {
                    Jsonb * subDataJb, * subSchemaJb;
                    subDataJb = JsonbValueToJsonb(&itemJbv);
                    subSchemaJb = JsonbValueToJsonb(&schemaJbv);
                    isItemValid = _is_jsonb_valid(subSchemaJb, subDataJb, root_schema);
                } else {
                    Jsonb * subDataJb;
                    // No more condition on items
                    if (additionalItemsJbv == NULL) {
                        break;
                    } else if (additionalItemsJbv->type == jbvBool) {
                        isValid = additionalItemsJbv->val.boolean;
                        break;
                    } else if (additionalItemsBuilt) {
                        subDataJb = JsonbValueToJsonb(&itemJbv);
                        isItemValid = _is_jsonb_valid(additionalItemsJb, subDataJb, root_schema);
                    } else if (additionalItemsJbv->type == jbvBinary) {
                        additionalItemsBuilt = true;
                        additionalItemsJb = JsonbValueToJsonb(additionalItemsJbv);
                        subDataJb = JsonbValueToJsonb(&itemJbv);
                        isItemValid = _is_jsonb_valid(additionalItemsJb, subDataJb, root_schema);
                    } else {
                        break;
                    }
                    isValid = isValid && isItemValid;
                }
        }
    }

    return isValid;
}

static bool validate_min (Jsonb * schemaJb, Jsonb * dataJb)
{
    JsonbIterator *it;
    JsonbValue	v;
    JsonbValue *minValue, *exclusiveMinValue;
    // bool isValid = true;
    if (!check_type(dataJb, "number", 6))
        return true;

    minValue = get_jbv_from_key(schemaJb, "minimum");

    if (minValue == NULL || minValue->type != jbvNumeric)
        return true;

	it = JsonbIteratorInit(&dataJb->root);
    // scalar is saved as array of one element
    (void) JsonbIteratorNext(&it, &v, true);
    Assert(v.type == jbvArray);
    (void) JsonbIteratorNext(&it, &v, true);

    if (DatumGetBool(DirectFunctionCall2(numeric_lt, PointerGetDatum(v.val.numeric), PointerGetDatum(minValue->val.numeric)))) {
        elog(INFO, "Value is not bigger than minimum");
        return false;
    }

    exclusiveMinValue = get_jbv_from_key(schemaJb, "exclusiveMinimum");

    if (exclusiveMinValue == NULL || exclusiveMinValue->type != jbvBool || exclusiveMinValue->val.boolean != true)
        return true;

    if (DatumGetBool(DirectFunctionCall2(numeric_eq, PointerGetDatum(v.val.numeric), PointerGetDatum(minValue->val.numeric)))) {
        elog(INFO, "Value is not strictly bigger than minimum");
        return false;
    }
    return true;
}

static bool validate_max (Jsonb * schemaJb, Jsonb * dataJb)
{
    JsonbIterator *it;
    JsonbValue	v;
    JsonbValue *maxValue, *exclusiveMaxValue;
    // bool isValid = true;
    if (!check_type(dataJb, "number", 6))
        return true;


    maxValue = get_jbv_from_key(schemaJb, "maximum");

    if (maxValue == NULL || maxValue->type != jbvNumeric)
        return true;

	it = JsonbIteratorInit(&dataJb->root);
    // scalar is saved as array of one element
    (void) JsonbIteratorNext(&it, &v, true);
    Assert(v.type == jbvArray);
    (void) JsonbIteratorNext(&it, &v, true);

    if (DatumGetBool(DirectFunctionCall2(numeric_gt, PointerGetDatum(v.val.numeric), PointerGetDatum(maxValue->val.numeric)))) {
        elog(INFO, "Value is not smaller than maximum");
        return false;
    }

    exclusiveMaxValue = get_jbv_from_key(schemaJb, "exclusiveMaximum");

    if (exclusiveMaxValue == NULL || exclusiveMaxValue->type != jbvBool || exclusiveMaxValue->val.boolean != true)
        return true;

    if (DatumGetBool(DirectFunctionCall2(numeric_eq, PointerGetDatum(v.val.numeric), PointerGetDatum(maxValue->val.numeric)))) {
        elog(INFO, "Value is not strictly smaller than maximum");
        return false;
    }
    return true;
}


static bool validate_any_of (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema)
{
    JsonbValue * propertyValue;
    JsonbIterator *it;
    JsonbValue v;
    JsonbIteratorToken r;
    Jsonb * anyOfJb;
    bool isValid = false;
    propertyValue = get_jbv_from_key(schemaJb, "anyOf");
    // It cannot be array
    if (propertyValue == NULL || propertyValue->type != jbvBinary) {
        return true;
    }
    anyOfJb = JsonbValueToJsonb(propertyValue);
    if (!JB_ROOT_IS_ARRAY(anyOfJb)) {
        return true;
    }
    it = JsonbIteratorInit(&anyOfJb->root);
    r = JsonbIteratorNext(&it, &v, true);
    Assert(r == WJB_BEGIN_ARRAY);

    while (!isValid) {
        Jsonb * subSchemaJb;
        r = JsonbIteratorNext(&it, &v, true);
        if (r == WJB_END_ARRAY)
            break;
        subSchemaJb = JsonbValueToJsonb(&v);
        isValid = isValid || _is_jsonb_valid(subSchemaJb, dataJb, root_schema);
    }

    return isValid;
}

static bool validate_all_of (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema)
{
    JsonbValue * propertyValue;
    JsonbIterator *it;
    JsonbValue v;
    JsonbIteratorToken r;
    Jsonb * allOfJb;
    bool isValid = true;
    propertyValue = get_jbv_from_key(schemaJb, "allOf");
    // It cannot be array
    if (propertyValue == NULL || propertyValue->type != jbvBinary) {
        return true;
    }
    allOfJb = JsonbValueToJsonb(propertyValue);
    if (!JB_ROOT_IS_ARRAY(allOfJb)) {
        return true;
    }
    it = JsonbIteratorInit(&allOfJb->root);
    r = JsonbIteratorNext(&it, &v, true);
    Assert(r == WJB_BEGIN_ARRAY);

    while (isValid) {
        Jsonb * subSchemaJb;
        r = JsonbIteratorNext(&it, &v, true);
        if (r == WJB_END_ARRAY)
            break;
        subSchemaJb = JsonbValueToJsonb(&v);
        isValid = isValid && _is_jsonb_valid(subSchemaJb, dataJb, root_schema);
    }

    return isValid;
}

static bool validate_one_of (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema)
{
    JsonbValue * propertyValue;
    JsonbIterator *it;
    JsonbValue v;
    JsonbIteratorToken r;
    Jsonb * oneOfJb;
    int countValid = 0;
    propertyValue = get_jbv_from_key(schemaJb, "oneOf");
    // It cannot be array
    if (propertyValue == NULL || propertyValue->type != jbvBinary) {
        return true;
    }
    oneOfJb = JsonbValueToJsonb(propertyValue);
    if (!JB_ROOT_IS_ARRAY(oneOfJb)) {
        return true;
    }
    it = JsonbIteratorInit(&oneOfJb->root);
    r = JsonbIteratorNext(&it, &v, true);
    Assert(r == WJB_BEGIN_ARRAY);

    while (countValid < 2) {
        Jsonb * subSchemaJb;
        r = JsonbIteratorNext(&it, &v, true);
        if (r == WJB_END_ARRAY)
            break;
        subSchemaJb = JsonbValueToJsonb(&v);
        if (_is_jsonb_valid(subSchemaJb, dataJb, root_schema))
            countValid += 1;
    }

    return countValid == 1;
}

static bool _is_jsonb_valid (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema)
{
    JsonbValue propertyKey;
    JsonbValue * propertyValue;
    text* key;
    bool isValid = true;
    propertyKey.type = jbvString;
    if (schemaJb == NULL)
        ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE), errmsg("Schema cannot be undefined")));
    // TODO probably assert schemaJb is object

    // required
    key = cstring_to_text("required");
    propertyKey.val.string.val = VARDATA_ANY(key);
    propertyKey.val.string.len = VARSIZE_ANY_EXHDR(key);

    propertyValue = findJsonbValueFromContainer(&schemaJb->root, JB_FOBJECT, &propertyKey);


    if (dataJb == NULL) {
        // required
        if (propertyValue != NULL && propertyValue->type == jbvBool) {
               return propertyValue->val.boolean != true;

        }
        return true;
    }
    // TODO required as object

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
            bool isPropertiesCorrect;
            isPropertiesCorrect = check_properties(dataJb, propertyValue, root_schema);
            isValid = isValid && isPropertiesCorrect;
    }

    // items
    key = cstring_to_text("items");
    propertyKey.val.string.val = VARDATA_ANY(key);
    propertyKey.val.string.len = VARSIZE_ANY_EXHDR(key);

    propertyValue = findJsonbValueFromContainer(&schemaJb->root, JB_FOBJECT, &propertyKey);

    if (propertyValue != NULL) {
        JsonbValue additionalItemsKeyJb;
        JsonbValue * additionalItemsJb;
        text* additionalItemsKey;
        additionalItemsKeyJb.type = jbvString;
        additionalItemsKey = cstring_to_text("additionalItems");
        additionalItemsKeyJb.val.string.val = VARDATA_ANY(additionalItemsKey);
        additionalItemsKeyJb.val.string.len = VARSIZE_ANY_EXHDR(additionalItemsKey);

        additionalItemsJb = findJsonbValueFromContainer(&schemaJb->root, JB_FOBJECT, &additionalItemsKeyJb);
        isValid = isValid && check_items(dataJb, propertyValue, additionalItemsJb, root_schema);
    }

    isValid = isValid && validate_min(schemaJb, dataJb);
    isValid = isValid && validate_max(schemaJb, dataJb);
    isValid = isValid && validate_any_of(schemaJb, dataJb, root_schema);
    isValid = isValid && validate_all_of(schemaJb, dataJb, root_schema);
    isValid = isValid && validate_one_of(schemaJb, dataJb, root_schema);

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


static JsonbValue * get_jbv_from_key (Jsonb * in, const char * key)
{
    JsonbValue propertyKey;
    JsonbValue * propertyValue;
    text* keyText;
    propertyKey.type = jbvString;
    keyText = cstring_to_text(key);
    propertyKey.val.string.val = VARDATA_ANY(keyText);
    propertyKey.val.string.len = VARSIZE_ANY_EXHDR(keyText);
    // findJsonbValueFromContainer returns palloced value
    propertyValue = findJsonbValueFromContainer(&in->root, JB_FOBJECT, &propertyKey);
    return propertyValue;
}
// elog(INFO, "%d", strcmp(propertyValue->val.string.val, "object"));

