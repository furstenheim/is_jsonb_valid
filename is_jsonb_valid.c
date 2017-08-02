#include "postgres.h"
#include "catalog/pg_type.h"
#include "fmgr.h"
#include "utils/builtins.h"
#include "catalog/pg_collation.h"
#include "utils/jsonb.h"
#define DEBUG_IS_JSONB_VALID false
PG_MODULE_MAGIC;

static bool _is_jsonb_valid (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema);
static bool check_required (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema);
static bool check_type (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema);
static bool check_properties (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema);
static bool check_items (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema);
static bool validate_min (Jsonb * schemaJb, Jsonb * dataJb);
static bool validate_max (Jsonb * schemaJb, Jsonb * dataJb);
static bool validate_any_of (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema);
static bool validate_all_of (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema);
static bool validate_one_of (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema);
static bool validate_unique_items (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema);
static bool validate_enum (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema);
static bool validate_length (Jsonb * schemaJb, Jsonb * dataJb);
static bool validate_not (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema);
static bool validate_num_properties (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema);
static bool validate_num_items (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema);
static bool validate_dependencies (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema);
static bool validate_pattern (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema);
static bool validate_multiple_of (Jsonb * schemaJb, Jsonb * dataJb);
static bool _is_jsonb_valid (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema);
static JsonbValue * get_jbv_from_key (Jsonb * in, const char * key);

PG_FUNCTION_INFO_V1(is_jsonb_valid);
Datum
is_jsonb_valid(PG_FUNCTION_ARGS)
{
    Jsonb *my_schema = PG_GETARG_JSONB(0);
    Jsonb *my_jsonb = PG_GETARG_JSONB(1);
    bool is_valid = _is_jsonb_valid(my_schema, my_jsonb, my_schema);
    PG_RETURN_BOOL(is_valid);
}

static bool _is_jsonb_valid (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema)
{
    JsonbValue * requiredValue;
    bool isValid = true;
    requiredValue = get_jbv_from_key(schemaJb, "required");
    if (schemaJb == NULL)
        ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE), errmsg("Schema cannot be undefined")));
    if (!JB_ROOT_IS_OBJECT(schemaJb))
        ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE), errmsg("Schema must be an object")));
    // If jb is null then we still have to check for required
    if (dataJb == NULL) {
        if (requiredValue != NULL && requiredValue->type == jbvBool) {
               return requiredValue->val.boolean != true;
        }
        return true;
    }

    isValid = isValid && check_required(schemaJb, dataJb, root_schema);

    isValid = isValid && check_type(schemaJb, dataJb, root_schema);
    isValid = isValid && check_properties(schemaJb, dataJb, root_schema);
    isValid = isValid && check_items(schemaJb, dataJb, root_schema);

    isValid = isValid && validate_min(schemaJb, dataJb);
    isValid = isValid && validate_max(schemaJb, dataJb);
    isValid = isValid && validate_any_of(schemaJb, dataJb, root_schema);
    isValid = isValid && validate_all_of(schemaJb, dataJb, root_schema);
    isValid = isValid && validate_one_of(schemaJb, dataJb, root_schema);
    isValid = isValid && validate_unique_items(schemaJb, dataJb, root_schema);

    // TODO ref

    isValid = isValid && validate_enum(schemaJb, dataJb, root_schema);
    isValid = isValid && validate_length(schemaJb, dataJb);
    isValid = isValid && validate_not(schemaJb, dataJb, root_schema);
    isValid = isValid && validate_num_properties(schemaJb, dataJb, root_schema);
    isValid = isValid && validate_num_items(schemaJb, dataJb, root_schema);
    isValid = isValid && validate_dependencies(schemaJb, dataJb, root_schema);
    isValid = isValid && validate_pattern(schemaJb, dataJb, root_schema);
    //isValid = isValid && validate_pattern_properties(schemaJb, dataJb, root_schema);
    isValid = isValid && validate_multiple_of(schemaJb, dataJb);

    return isValid;
}



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



// Taken from jsonb_typeof
static bool is_type_correct(Jsonb * in, char * type, int typeLen)
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

static bool check_required (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema)
{
    JsonbValue * requiredValue;
    Jsonb * requiredJb;
    JsonbIterator *it;
    JsonbIteratorToken r;
    JsonbValue v;
    bool isValid = true;
    requiredValue = get_jbv_from_key(schemaJb, "required");

    if (!JB_ROOT_IS_OBJECT(dataJb) || requiredValue == NULL || requiredValue->type != jbvBinary)
        return true;
    requiredJb = JsonbValueToJsonb(requiredValue);
    if (!JB_ROOT_IS_ARRAY(requiredJb))
        ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE), errmsg("Required must be boolean or array")));
    it = JsonbIteratorInit(&requiredJb->root);
    r = JsonbIteratorNext(&it, &v, true);
    Assert(r == WJB_BEGIN_ARRAY);
    while (isValid) {
        JsonbValue *propertyJbv;
        r = JsonbIteratorNext(&it, &v, true);
        if (r == WJB_END_ARRAY)
            break;
        if (v.type != jbvString)
          ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE), errmsg("Required items must be strings")));
        propertyJbv = findJsonbValueFromContainer(&dataJb->root, JB_FOBJECT, &v);
        isValid = isValid && (propertyJbv != NULL);
    }
    return isValid;
}

static bool check_type (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema)
{
    JsonbValue *typeJbv;
    Jsonb * typeJb;

    typeJbv = get_jbv_from_key(schemaJb, "type");

    if (typeJbv == NULL)
        return true;

    if (typeJbv->type == jbvString) {
        bool isValid = is_type_correct(dataJb, typeJbv->val.string.val, typeJbv->val.string.len);
        return isValid;
    } else if (typeJbv->type == jbvBinary) {
        bool isValid = false;
        JsonbIteratorToken r;
        JsonbIterator * it;
        JsonbValue v;
        typeJb = JsonbValueToJsonb(typeJbv);
        if (!JB_ROOT_IS_ARRAY(typeJb))
           ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE), errmsg("type must be string or array")));
        it = JsonbIteratorInit(&typeJb->root);
        r = JsonbIteratorNext(&it, &v, true);
        Assert(r == WJB_BEGIN_ARRAY);
        while (!isValid) {
            Jsonb * subSchemaJb;
            r = JsonbIteratorNext(&it, &v, true);
            if (r == WJB_END_ARRAY)
                break;
            if (v.type == jbvString) {
                isValid = isValid || is_type_correct(dataJb, v.val.string.val, v.val.string.len);
            } else if (v.type == jbvBinary) {
                subSchemaJb = JsonbValueToJsonb(&v);
                if (!JB_ROOT_IS_OBJECT(subSchemaJb))
                    ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE), errmsg("type elements must be strings or objects")));
                isValid = isValid || _is_jsonb_valid(subSchemaJb, dataJb, root_schema);
            } else {
                ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE), errmsg("type elements must be strings or objects")));
            }
        }
        return isValid;
    } else {
        ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE), errmsg("type elements must be strings or objects")));
    }
}

static bool check_properties (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema) {
    JsonbValue * propertiesJbv, * additionalPropertiesJbv, *patternPropertiesJbv;
    bool isValid = true;
    Jsonb * propertiesJb, * additionalPropertiesJb, *patternPropertiesJb;
    JsonbIterator * it, *pIt, *patternPropertiesIt;
    JsonbIteratorToken r, pR, ppR;
    JsonbValue v, pV;

    if (!JB_ROOT_IS_OBJECT(dataJb))
        return true;
    propertiesJbv = get_jbv_from_key(schemaJb, "properties");
    additionalPropertiesJbv = get_jbv_from_key(schemaJb, "additionalProperties");
    patternPropertiesJbv = get_jbv_from_key(schemaJb, "patternProperties");

    if (propertiesJbv == NULL && additionalPropertiesJbv == NULL && patternPropertiesJbv == NULL)
        return true;

    // Lots of cases here because if patternProperties is not present we can optimize a lot
    if (patternPropertiesJbv == NULL && propertiesJbv == NULL) {
        if (additionalPropertiesJbv->type == jbvBool) {
            if (additionalPropertiesJbv->val.boolean == true) {
                return true;
            }
            Assert(additionalPropertiesJbv->val.boolean == false);
            it = JsonbIteratorInit(&dataJb->root);
            r = JsonbIteratorNext(&it, &v, true);
            Assert(r == WJB_BEGIN_OBJECT);
            Assert(v.type == jbvObject);
            return v.val.object.nPairs == 0;
        } else if (additionalPropertiesJbv->type == jbvBinary) {
           additionalPropertiesJb = JsonbValueToJsonb(additionalPropertiesJbv);
           if (!JB_ROOT_IS_OBJECT(additionalPropertiesJb)) {
               ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE), errmsg("additionalProperties must be object or boolean")));
           }
           it = JsonbIteratorInit(&dataJb->root);
           r = JsonbIteratorNext(&it, &v, true);
           Assert(r == WJB_BEGIN_OBJECT);
           while (isValid) {
                Jsonb * subDataJb;
                r = JsonbIteratorNext(&it, &v, true);
                if (r == WJB_END_OBJECT)
                    break;
                r = JsonbIteratorNext(&it, &v, true);
                subDataJb = JsonbValueToJsonb(&v);
                isValid = isValid && _is_jsonb_valid(additionalPropertiesJb, subDataJb, root_schema);
           }
           return isValid;
        }
        // Unknown model
        ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE), errmsg("additionalProperties must be object or boolean")));
    } else if (patternPropertiesJbv == NULL) {
        propertiesJb = JsonbValueToJsonb(propertiesJbv);
        if (!JB_ROOT_IS_OBJECT(propertiesJb))
            ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE), errmsg("properties must be an object")));
        if (additionalPropertiesJbv != NULL)
            additionalPropertiesJb = JsonbValueToJsonb(additionalPropertiesJbv);
        // Sorted merged join to validate properties so O(#keys)
        it = JsonbIteratorInit(&dataJb->root);
        r = JsonbIteratorNext(&it, &v, true);
        Assert(r == WJB_BEGIN_OBJECT);
        pIt = JsonbIteratorInit(&propertiesJb->root);
        pR = JsonbIteratorNext(&pIt, &pV, true);
        Assert(pR == WJB_BEGIN_OBJECT);

        r = JsonbIteratorNext(&it, &v, true);
        pR = JsonbIteratorNext(&pIt, &pV, true);
        while (isValid && !(r == WJB_END_OBJECT && pR == WJB_END_OBJECT)) {
            Jsonb * subDataJb, * subSchemaJb;
            // keys are sorted, difference tells us which one we should iterate (0 means they are even)
            int difference;
            if (pR == WJB_END_OBJECT) {
                difference = -1;
            } else if (r == WJB_END_OBJECT) {
                difference = 1;
            } else {
                difference = lengthCompareJsonbStringValue(&v, &pV);
            }

            // Additional property
            if (difference < 0) {
                // Iterate once more to get the value (we had the key)
                r = JsonbIteratorNext(&it, &v, true);
                if (additionalPropertiesJbv != NULL) {
                    if (additionalPropertiesJbv->type == jbvBool && additionalPropertiesJbv->val.boolean == false) {
                        isValid = false;
                    } else if (JB_ROOT_IS_OBJECT(additionalPropertiesJb)) {
                        subDataJb = JsonbValueToJsonb(&v);
                        isValid = isValid && _is_jsonb_valid(additionalPropertiesJb, subDataJb, root_schema);
                    }
                }
                r = JsonbIteratorNext(&it, &v, true);
            } else if (difference > 0) {
                pR = JsonbIteratorNext(&pIt, &pV, true);
                // Mainly checking that property is not required
                subSchemaJb = JsonbValueToJsonb(&pV);
                isValid = isValid && _is_jsonb_valid(subSchemaJb, NULL, root_schema);
                pR = JsonbIteratorNext(&pIt, &pV, true);
            } else {
               r = JsonbIteratorNext(&it, &v, true);
               pR = JsonbIteratorNext(&pIt, &pV, true);
               subDataJb = JsonbValueToJsonb(&v);
               subSchemaJb = JsonbValueToJsonb(&pV);
               isValid = isValid && _is_jsonb_valid(subSchemaJb, subDataJb, root_schema);
               r = JsonbIteratorNext(&it, &v, true);
               pR = JsonbIteratorNext(&pIt, &pV, true);
            }
        }
        return isValid;
    } else {
        // patternProperties is defined
        // This is highly unoptimal. The least O(#keys #patternPropertiesKeys)
        JsonbValue k, ppK, ppV;
        if (additionalPropertiesJbv != NULL)
            additionalPropertiesJb = JsonbValueToJsonb(additionalPropertiesJbv);
        if (propertiesJbv != NULL) {
                propertiesJb = JsonbValueToJsonb(propertiesJbv);
                if (!JB_ROOT_IS_OBJECT(propertiesJb))
                    ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE), errmsg("properties must be object or boolean")));
        }
        patternPropertiesJb = JsonbValueToJsonb(patternPropertiesJbv);
        if (!JB_ROOT_IS_OBJECT(patternPropertiesJb)) {
            ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE), errmsg("patternProperties must be object or boolean")));
        }
        it = JsonbIteratorInit(&dataJb->root);
        r = JsonbIteratorNext(&it, &v, true);
        Assert(r == WJB_BEGIN_OBJECT);
        // Iterate over all keys of object, then all keys of patternProperties, then check property in properties. If none, then additionalProperties
        while (isValid) {
            bool keyMatched = false;
            Jsonb * subDataVJb;
            r = JsonbIteratorNext(&it, &k, true);
            if (r == WJB_END_OBJECT)
                break;
            r = JsonbIteratorNext(&it, &v, true);
            subDataVJb = JsonbValueToJsonb(&v);
            patternPropertiesIt = JsonbIteratorInit(&patternPropertiesJb->root);
            ppR = JsonbIteratorNext(&patternPropertiesIt, &ppK, true);
            Assert(ppR = WJB_BEGIN_OBJECT);
            while (isValid) {
                bool keyMatches;
                ppR = JsonbIteratorNext(&patternPropertiesIt, &ppK, true);
                if (ppR == WJB_END_OBJECT)
                    break;
                ppR = JsonbIteratorNext(&patternPropertiesIt, &ppV, true);
                keyMatches = DatumGetBool(DirectFunctionCall2Coll(textregexeq, DEFAULT_COLLATION_OID,
                                PointerGetDatum(cstring_to_text_with_len(k.val.string.val, k.val.string.len)),
                                PointerGetDatum(cstring_to_text_with_len(ppK.val.string.val, ppK.val.string.len))));
                if (DEBUG_IS_JSONB_VALID) elog(INFO, keyMatches ? "regex matched" : "regex did not matched");
                if (keyMatches) {
                       Jsonb * subSchemaJb;
                        subSchemaJb = JsonbValueToJsonb(&ppV);
                        isValid = isValid && _is_jsonb_valid(subSchemaJb, subDataVJb, root_schema);
                        keyMatched = true;
                }
            }
            if (propertiesJbv != NULL) {
                JsonbValue * subSchemaJbv;
                Jsonb * subSchemaJb;
                subSchemaJbv = findJsonbValueFromContainer(&propertiesJb->root, JB_FOBJECT, &k);
                if (subSchemaJbv != NULL) {
                    subSchemaJb = JsonbValueToJsonb(subSchemaJbv);
                    isValid = isValid && _is_jsonb_valid(subSchemaJb, subDataVJb, root_schema);
                    keyMatched = true;
                }
            }
            if (keyMatched != true && additionalPropertiesJbv != NULL) {
                if (additionalPropertiesJbv->type == jbvBool && additionalPropertiesJbv->val.boolean == false) {
                    isValid = false;
                } else if (JB_ROOT_IS_OBJECT(additionalPropertiesJb)) {
                    isValid = isValid && _is_jsonb_valid(additionalPropertiesJb, subDataVJb, root_schema);
                }
            }
        }
        return isValid;
    }
}

static bool check_items (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema) {
    JsonbValue * itemsValue, * additionalItemsJbv;
    bool isValid = true;
    Jsonb * itemsObject;
    JsonbIterator * it;
    JsonbIteratorToken r;
    JsonbValue itemJbv;
    if (!JB_ROOT_IS_ARRAY(dataJb)) return isValid;
    itemsValue = get_jbv_from_key(schemaJb, "items");

    if (itemsValue == NULL)
        return true;

    additionalItemsJbv = get_jbv_from_key(schemaJb, "additionalItems");
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
            if (DEBUG_IS_JSONB_VALID) elog(INFO, isItemValid ? "Item is valid" : "Item is not valid");
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
    if (!is_type_correct(dataJb, "number", 6))
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
        if (DEBUG_IS_JSONB_VALID) elog(INFO, "Value is not bigger than minimum");
        return false;
    }

    exclusiveMinValue = get_jbv_from_key(schemaJb, "exclusiveMinimum");

    if (exclusiveMinValue == NULL || exclusiveMinValue->type != jbvBool || exclusiveMinValue->val.boolean != true)
        return true;

    if (DatumGetBool(DirectFunctionCall2(numeric_eq, PointerGetDatum(v.val.numeric), PointerGetDatum(minValue->val.numeric)))) {
        if (DEBUG_IS_JSONB_VALID) elog(INFO, "Value is not strictly bigger than minimum");
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
    if (!is_type_correct(dataJb, "number", 6))
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
        if (DEBUG_IS_JSONB_VALID) elog(INFO, "Value is not smaller than maximum");
        return false;
    }

    exclusiveMaxValue = get_jbv_from_key(schemaJb, "exclusiveMaximum");

    if (exclusiveMaxValue == NULL || exclusiveMaxValue->type != jbvBool || exclusiveMaxValue->val.boolean != true)
        return true;

    if (DatumGetBool(DirectFunctionCall2(numeric_eq, PointerGetDatum(v.val.numeric), PointerGetDatum(maxValue->val.numeric)))) {
        if (DEBUG_IS_JSONB_VALID) elog(INFO, "Value is not strictly smaller than maximum");
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

static bool validate_unique_items (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema)
{
        JsonbValue * propertyValue;
        JsonbIterator *it;
        JsonbValue v;
        JsonbIteratorToken r;
        bool isValid = true;
        int i = 0;
        propertyValue = get_jbv_from_key(schemaJb, "uniqueItems");
        // It cannot be array
        if (!JB_ROOT_IS_ARRAY(dataJb) || propertyValue == NULL || propertyValue->type != jbvBool || propertyValue->val.boolean == false) {
            return true;
        }
        // Warning this is O(n2)
        it = JsonbIteratorInit(&dataJb->root);
        r = JsonbIteratorNext(&it, &v, true);
        Assert(r == WJB_BEGIN_ARRAY);
        while (isValid) {
            JsonbIterator *it2;
            JsonbValue v2;
            JsonbIteratorToken r2;
            Jsonb * subDataJb1;
            int j = 0;
            r = JsonbIteratorNext(&it, &v, true);
            i++;
            if (r == WJB_END_ARRAY)
                break;
            subDataJb1 = JsonbValueToJsonb(&v);
            it2 = JsonbIteratorInit(&dataJb->root);
            r2 = JsonbIteratorNext(&it2, &v2, true);
            Assert(r2 == WJB_BEGIN_ARRAY);
            while (isValid) {
                Jsonb * subDataJb2;
                r2 = JsonbIteratorNext(&it2, &v2, true);
                j++;
                if (j >= i)
                    break;
                subDataJb2 = JsonbValueToJsonb(&v2);
                isValid = isValid && (compareJsonbContainers(&subDataJb1->root, &subDataJb2->root) != 0);
            }
        }
        return isValid;
}

static bool validate_enum (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema)
{
        JsonbValue * propertyValue;
        Jsonb * enumJb;
        JsonbIterator *it;
        JsonbValue v;
        JsonbIteratorToken r;
        bool isValid = false;
        propertyValue = get_jbv_from_key(schemaJb, "enum");
        if (propertyValue == NULL || propertyValue->type != jbvBinary)
        {
            return true;
        }
        enumJb = JsonbValueToJsonb(propertyValue);
        if (!JB_ROOT_IS_ARRAY(enumJb))
            return true;
        it = JsonbIteratorInit(&enumJb->root);
        r = JsonbIteratorNext(&it, &v, true);
        Assert(r == WJB_BEGIN_ARRAY);
        while (!isValid) {
            Jsonb * subSchemaJb;
            r = JsonbIteratorNext(&it, &v, true);
            if (r == WJB_END_ARRAY)
                break;
            subSchemaJb = JsonbValueToJsonb(&v);
            isValid = isValid || (compareJsonbContainers(&dataJb->root, &subSchemaJb->root) == 0);
        }

        return isValid;
}

static bool validate_length (Jsonb * schemaJb, Jsonb * dataJb)
{
    JsonbIterator *it;
    JsonbValue	v;
    JsonbValue *minLengthValue, *maxLengthValue;
    bool isValid = true;
    // bool isValid = true;
    if (!is_type_correct(dataJb, "string", 6))
        return true;

	it = JsonbIteratorInit(&dataJb->root);
    // scalar is saved as array of one element
    (void) JsonbIteratorNext(&it, &v, true);
    Assert(v.type == jbvArray);
    (void) JsonbIteratorNext(&it, &v, true);


    minLengthValue = get_jbv_from_key(schemaJb, "minLength");

    if (minLengthValue != NULL && minLengthValue->type == jbvNumeric) {
        int length = DatumGetInt32(DirectFunctionCall1(textlen, PointerGetDatum(cstring_to_text_with_len(v.val.string.val, v.val.string.len))));
        
        if (DEBUG_IS_JSONB_VALID) elog(INFO, "Length is %d", length);
        isValid = isValid && DatumGetBool(DirectFunctionCall2(numeric_ge, DirectFunctionCall1(int4_numeric, length), PointerGetDatum(minLengthValue->val.numeric)));
    }

    maxLengthValue = get_jbv_from_key(schemaJb, "maxLength");

    if (maxLengthValue != NULL && maxLengthValue->type == jbvNumeric) {
        int length = DatumGetInt32(DirectFunctionCall1(textlen, PointerGetDatum(cstring_to_text_with_len(v.val.string.val, v.val.string.len))));
        isValid = isValid && DatumGetBool(DirectFunctionCall2(numeric_le, DirectFunctionCall1(int4_numeric, length), PointerGetDatum(maxLengthValue->val.numeric)));
    }
    return isValid;
}

static bool validate_not (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema)
{
    JsonbValue * propertyValue;
    Jsonb * notJb;
    propertyValue = get_jbv_from_key(schemaJb, "not");
    // It cannot be array
    if (propertyValue == NULL || propertyValue->type != jbvBinary) {
        return true;
    }
    notJb = JsonbValueToJsonb(propertyValue);
    if (!JB_ROOT_IS_OBJECT(notJb)) {
        return true;
    }
    return !_is_jsonb_valid(notJb, dataJb, root_schema);
}

static bool validate_num_properties (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema)
{
    JsonbValue * maxProperties, * minProperties;
    JsonbIterator *it;
    JsonbIteratorToken r;
    JsonbValue v;
    bool isValid = true;

    //int numProperties = 0;

    if (!JB_ROOT_IS_OBJECT(dataJb))
        return true;

    minProperties = get_jbv_from_key(schemaJb, "minProperties");
    maxProperties = get_jbv_from_key(schemaJb, "maxProperties");

    if (minProperties == NULL && maxProperties == NULL)
        return true;

    it = JsonbIteratorInit(&dataJb->root);
    r = JsonbIteratorNext(&it, &v, true);
    Assert(r == WJB_BEGIN_OBJECT);
    Assert(v.type == jbvObject);

    if (minProperties != NULL && minProperties->type == jbvNumeric)
        isValid = isValid && DatumGetBool(DirectFunctionCall2(numeric_ge, DirectFunctionCall1(int4_numeric, v.val.object.nPairs), PointerGetDatum(minProperties->val.numeric)));
    if (maxProperties != NULL && maxProperties->type == jbvNumeric)
        isValid = isValid && DatumGetBool(DirectFunctionCall2(numeric_le, DirectFunctionCall1(int4_numeric, v.val.object.nPairs), PointerGetDatum(maxProperties->val.numeric)));
    return isValid;
}

static bool validate_num_items (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema)
{
    JsonbValue * maxItems, * minItems;
    JsonbIterator *it;
    JsonbIteratorToken r;
    JsonbValue v;
    bool isValid = true;

    //int numItems = 0;

    if (!JB_ROOT_IS_ARRAY(dataJb))
        return true;

    minItems = get_jbv_from_key(schemaJb, "minItems");
    maxItems = get_jbv_from_key(schemaJb, "maxItems");

    if (minItems == NULL && maxItems == NULL)
        return true;

    it = JsonbIteratorInit(&dataJb->root);
    r = JsonbIteratorNext(&it, &v, true);
    Assert(r == WJB_BEGIN_ARRAY);
    Assert(v.type == jbvArray);

    if (minItems != NULL && minItems->type == jbvNumeric)
        isValid = isValid && DatumGetBool(DirectFunctionCall2(numeric_ge, DirectFunctionCall1(int4_numeric, v.val.array.nElems), PointerGetDatum(minItems->val.numeric)));
    if (maxItems != NULL && maxItems->type == jbvNumeric)
        isValid = isValid && DatumGetBool(DirectFunctionCall2(numeric_le, DirectFunctionCall1(int4_numeric, v.val.array.nElems), PointerGetDatum(maxItems->val.numeric)));
    return isValid;
}

// TODO validate against malformed types
static bool validate_dependencies (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema)
{
    JsonbValue *propertyKey;
    Jsonb *dependenciesJb;
    JsonbIterator * it;
    JsonbValue k, v;
    JsonbIteratorToken r;
    bool isValid = true;

    if (!JB_ROOT_IS_OBJECT(dataJb))
        return true;

    propertyKey = get_jbv_from_key(schemaJb, "dependencies");
    if (propertyKey == NULL || propertyKey->type != jbvBinary)
        return true;

    dependenciesJb = JsonbValueToJsonb(propertyKey);
    it = JsonbIteratorInit(&dependenciesJb->root);
    r = JsonbIteratorNext(&it, &v, true);
    Assert(r == WJB_BEGIN_OBJECT);
    while (isValid) {
        JsonbValue * dataProperty;
        r = JsonbIteratorNext(&it, &k, true);
        if (r == WJB_END_OBJECT)
            break;
        r = JsonbIteratorNext(&it, &v, true);
        dataProperty = findJsonbValueFromContainer(&dataJb->root, JB_FOBJECT, &k);
        if (dataProperty != NULL) {
            if (v.type == jbvString) {
                JsonbValue * dependentProperty;
                dependentProperty = findJsonbValueFromContainer(&dataJb->root, JB_FOBJECT, &v);
                isValid = isValid && (dependentProperty != NULL);
            } else if (v.type == jbvBinary) {
                Jsonb * dependencyJb;
                dependencyJb = JsonbValueToJsonb(&v);

                if (JB_ROOT_IS_ARRAY(dependencyJb)) {
                    JsonbIterator * dependencyIt;
                    JsonbIteratorToken dependencyR;
                    JsonbValue dependencyKey;

                    dependencyIt = JsonbIteratorInit(&dependencyJb->root);
                    dependencyR = JsonbIteratorNext(&dependencyIt, &dependencyKey, true);
                    Assert(dependencyR == WJB_BEGIN_ARRAY);
                    while (isValid) {
                        JsonbValue * dependantProperty;
                        dependencyR = JsonbIteratorNext(&dependencyIt, &dependencyKey, true);
                        if (dependencyR == WJB_END_ARRAY)
                            break;
                        if (dependencyKey.type == jbvString) {
                            dependantProperty = findJsonbValueFromContainer(&dataJb->root, JB_FOBJECT, &dependencyKey);
                            isValid = isValid && (dependantProperty != NULL);
                        }
                    }
                } else if (JB_ROOT_IS_OBJECT(dependencyJb)) {
                    isValid = isValid && _is_jsonb_valid(dependencyJb, dataJb, root_schema);
                }
            }
        }
    }
    return isValid;
}

static bool validate_pattern (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema)
{
    JsonbIterator *it;
    JsonbValue	v;
    JsonbValue *pattern;
    bool isValid = true;
    // bool isValid = true;
    if (!is_type_correct(dataJb, "string", 6))
        return true;
    pattern = get_jbv_from_key(schemaJb, "pattern");
    if (pattern == NULL) {
        return true;
    }
	it = JsonbIteratorInit(&dataJb->root);
    // scalar is saved as array of one element
    (void) JsonbIteratorNext(&it, &v, true);
    Assert(v.type == jbvArray);
    (void) JsonbIteratorNext(&it, &v, true);


    if (pattern->type == jbvString) {
        return DatumGetBool(DirectFunctionCall2Coll(textregexeq, DEFAULT_COLLATION_OID,
            PointerGetDatum(cstring_to_text_with_len(v.val.string.val, v.val.string.len)),
            PointerGetDatum(cstring_to_text_with_len(pattern->val.string.val, pattern->val.string.len))));
    }
    return isValid;
}

static bool validate_multiple_of (Jsonb * schemaJb, Jsonb * dataJb)
{
    JsonbIterator *it;
    JsonbValue	v;
    JsonbValue *multipleOfValue;
    Numeric dividend;
    // bool isValid = true;
    if (!is_type_correct(dataJb, "number", 6))
        return true;


    multipleOfValue = get_jbv_from_key(schemaJb, "multipleOf");

    if (multipleOfValue == NULL || multipleOfValue->type != jbvNumeric)
        return true;

	it = JsonbIteratorInit(&dataJb->root);
    // scalar is saved as array of one element
    (void) JsonbIteratorNext(&it, &v, true);
    Assert(v.type == jbvArray);
    (void) JsonbIteratorNext(&it, &v, true);

    dividend = DatumGetNumeric(DirectFunctionCall2(numeric_div, PointerGetDatum(v.val.numeric), PointerGetDatum(multipleOfValue->val.numeric)));
    return DatumGetBool(DirectFunctionCall2(
                                numeric_eq,
                                PointerGetDatum(dividend),
                                DirectFunctionCall1(numeric_floor, PointerGetDatum(dividend))));
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

