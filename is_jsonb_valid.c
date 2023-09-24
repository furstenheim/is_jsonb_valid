#include "postgres.h"
#include "catalog/pg_type.h"
#include "fmgr.h"
#include <limits.h>
#include "utils/builtins.h"
#include "catalog/pg_collation.h"
#include "utils/jsonb.h"
#define DEBUG_IS_JSONB_VALID false

// Not very nice, but it is only defined internally
#define JsonContainerIsArray(jc)	(((jc)->header & JB_FARRAY) != 0)
#define JsonContainerSize(jc)		((jc)->header & JB_CMASK)
#define _unused(x) ((void)(x))

PG_MODULE_MAGIC;

static bool _is_jsonb_valid (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema);
static bool validate_required (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema);
static bool validate_type (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema);
static bool validate_properties (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema);
static bool validate_items (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema);
static bool validate_min (Jsonb * schemaJb, Jsonb * dataJb);
static bool validate_max (Jsonb * schemaJb, Jsonb * dataJb);
static bool validate_any_of (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema);
static bool validate_all_of (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema);
static bool validate_one_of (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema);
static bool validate_unique_items (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema);
static bool validate_ref (JsonbValue * refJbv, Jsonb * dataJb, Jsonb * root_schema);
static bool validate_enum (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema);
static bool validate_length (Jsonb * schemaJb, Jsonb * dataJb);
static bool validate_not (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema);
static bool validate_num_properties (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema);
static bool validate_num_items (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema);
static bool validate_dependencies (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema);
static bool validate_pattern (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema);
static bool validate_multiple_of (Jsonb * schemaJb, Jsonb * dataJb);
static JsonbValue * get_jbv_from_key (Jsonb * in, const char * key);

PG_FUNCTION_INFO_V1(is_jsonb_valid);
Datum
is_jsonb_valid(PG_FUNCTION_ARGS)
{
    #ifdef PG_GETARG_JSONB_P
        Jsonb *my_schema = PG_GETARG_JSONB_P(0);
        Jsonb *my_jsonb = PG_GETARG_JSONB_P(1);
    #else
        Jsonb *my_schema = PG_GETARG_JSONB(0);
        Jsonb *my_jsonb = PG_GETARG_JSONB(1);
    #endif
    bool is_valid = _is_jsonb_valid(my_schema, my_jsonb, my_schema);
    PG_RETURN_BOOL(is_valid);
}

static bool _is_jsonb_valid (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema)
{
    JsonbValue * requiredValue, * refJbv;
    bool isValid = true;
    if (schemaJb == NULL)
        ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE), errmsg("Schema cannot be undefined")));
    if (!JB_ROOT_IS_OBJECT(schemaJb))
        ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE), errmsg("Schema must be an object")));

    requiredValue = get_jbv_from_key(schemaJb, "required");
    refJbv = get_jbv_from_key(schemaJb, "$ref");
    // $ref overrides rest of properties
    if (refJbv != NULL) {
        return validate_ref(refJbv, dataJb, root_schema);
    }

    // If jb is null then we still have to check for required
    if (dataJb == NULL) {
        if (requiredValue != NULL && requiredValue->type == jbvBool) {
               return requiredValue->val.boolean != true;
        }
        return true;
    }



    isValid = isValid && validate_required(schemaJb, dataJb, root_schema);

    isValid = isValid && validate_type(schemaJb, dataJb, root_schema);
    isValid = isValid && validate_properties(schemaJb, dataJb, root_schema);
    isValid = isValid && validate_items(schemaJb, dataJb, root_schema);

    isValid = isValid && validate_min(schemaJb, dataJb);
    isValid = isValid && validate_max(schemaJb, dataJb);
    isValid = isValid && validate_any_of(schemaJb, dataJb, root_schema);
    isValid = isValid && validate_all_of(schemaJb, dataJb, root_schema);
    isValid = isValid && validate_one_of(schemaJb, dataJb, root_schema);
    isValid = isValid && validate_unique_items(schemaJb, dataJb, root_schema);
    isValid = isValid && validate_enum(schemaJb, dataJb, root_schema);
    isValid = isValid && validate_length(schemaJb, dataJb);
    isValid = isValid && validate_not(schemaJb, dataJb, root_schema);
    isValid = isValid && validate_num_properties(schemaJb, dataJb, root_schema);
    isValid = isValid && validate_num_items(schemaJb, dataJb, root_schema);
    isValid = isValid && validate_dependencies(schemaJb, dataJb, root_schema);
    isValid = isValid && validate_pattern(schemaJb, dataJb, root_schema);
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

/**
* Scalar jsonb are stored in an array
*/
static bool
root_is_really_an_array (Jsonb * jb) {
    return JB_ROOT_IS_ARRAY(jb) && !JB_ROOT_IS_SCALAR(jb);
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
}

static bool validate_required (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema)
{
    JsonbValue * requiredJbv;
    Jsonb * requiredJb;
    JsonbIterator *it;
    JsonbIteratorToken r;
    JsonbValue v;
    bool isValid = true;
    requiredJbv = get_jbv_from_key(schemaJb, "required");

    if (!JB_ROOT_IS_OBJECT(dataJb) || requiredJbv == NULL || requiredJbv->type != jbvBinary)
        return true;
    requiredJb = JsonbValueToJsonb(requiredJbv);
    if (!root_is_really_an_array(requiredJb))
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

static bool validate_type (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema)
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
        if (!root_is_really_an_array(typeJb))
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

static bool validate_properties (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema) {
    JsonbValue * propertiesJbv, * additionalPropertiesJbv, *patternPropertiesJbv;
    bool isValid = true;
    Jsonb * propertiesJb = NULL;
    Jsonb * patternPropertiesJb = NULL;
    Jsonb * additionalPropertiesJb = NULL;
    JsonbIterator * it, *pIt, *ppIt;
    JsonbIteratorToken r, pR, ppR;

    if (!JB_ROOT_IS_OBJECT(dataJb))
        return true;
    propertiesJbv = get_jbv_from_key(schemaJb, "properties");
    additionalPropertiesJbv = get_jbv_from_key(schemaJb, "additionalProperties");
    patternPropertiesJbv = get_jbv_from_key(schemaJb, "patternProperties");

    if (propertiesJbv == NULL && additionalPropertiesJbv == NULL && patternPropertiesJbv == NULL)
        return true;

    // Lots of cases here because if patternProperties is not present we can optimize a lot
    if (patternPropertiesJbv == NULL && propertiesJbv == NULL) {
        JsonbValue v;
        // If additionalProperties is false check there are no properties
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
            // We check all properties against additional properties
        } else if (additionalPropertiesJbv->type == jbvBinary) {
           JsonbValue k;
           additionalPropertiesJb = JsonbValueToJsonb(additionalPropertiesJbv);
           if (!JB_ROOT_IS_OBJECT(additionalPropertiesJb)) {
               ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE), errmsg("additionalProperties must be object or boolean")));
           }
           it = JsonbIteratorInit(&dataJb->root);
           r = JsonbIteratorNext(&it, &k, true);
           Assert(r == WJB_BEGIN_OBJECT);
           while (isValid) {
                Jsonb * subDataJb;
                r = JsonbIteratorNext(&it, &k, true);
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
    /*
     * Sorted merged join to validate properties so O(#keys)
     * we traverse dataJb and propertiesJb simultaneously.
     * If a property is present in the schema but not in the object (difference > 0) we check if the property was required
     * If the property is present in the object but not in the schema (difference < 0) we check the value against additionalProperties
    */
    } else if (patternPropertiesJbv == NULL) {
        JsonbValue v, pV, k, pK;
        propertiesJb = JsonbValueToJsonb(propertiesJbv);
        if (!JB_ROOT_IS_OBJECT(propertiesJb))
            ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE), errmsg("properties must be an object")));
        if (additionalPropertiesJbv != NULL)
            additionalPropertiesJb = JsonbValueToJsonb(additionalPropertiesJbv);
        it = JsonbIteratorInit(&dataJb->root);
        r = JsonbIteratorNext(&it, &v, true);
        Assert(r == WJB_BEGIN_OBJECT);
        pIt = JsonbIteratorInit(&propertiesJb->root);
        pR = JsonbIteratorNext(&pIt, &pV, true);
        Assert(pR == WJB_BEGIN_OBJECT);

        r = JsonbIteratorNext(&it, &k, true);
        pR = JsonbIteratorNext(&pIt, &pK, true);
        while (isValid && !(r == WJB_END_OBJECT && pR == WJB_END_OBJECT)) {
            Jsonb * subDataJb, * subSchemaJb;
            // keys are sorted, difference tells us which one we should iterate (0 means they are even)
            int difference;
            if (pR == WJB_END_OBJECT) {
                difference = -1;
            } else if (r == WJB_END_OBJECT) {
                difference = 1;
            } else {
                difference = lengthCompareJsonbStringValue(&k, &pK);
            }

            // Additional property
            if (difference < 0) {
                // Iterate once more to get the value (we had the key)
                r = JsonbIteratorNext(&it, &v, true);
                if (additionalPropertiesJbv != NULL) {
                    if (additionalPropertiesJbv->type == jbvBool && additionalPropertiesJbv->val.boolean == false) {
                        if (DEBUG_IS_JSONB_VALID)
                            elog(INFO, "additional property %*.*s", k.val.string.len, k.val.string.len, k.val.string.val);
                       isValid = false;
                    } else if (JB_ROOT_IS_OBJECT(additionalPropertiesJb)) {
                        subDataJb = JsonbValueToJsonb(&v);
                        isValid = isValid && _is_jsonb_valid(additionalPropertiesJb, subDataJb, root_schema);
                    }
                }
                r = JsonbIteratorNext(&it, &k, true);
            } else if (difference > 0) {
                pR = JsonbIteratorNext(&pIt, &pV, true);
                // Mainly checking that property is not required
                subSchemaJb = JsonbValueToJsonb(&pV);
                isValid = isValid && _is_jsonb_valid(subSchemaJb, NULL, root_schema);
                pR = JsonbIteratorNext(&pIt, &pK, true);
            } else {
               bool isPropertyValid;
               r = JsonbIteratorNext(&it, &v, true);
               pR = JsonbIteratorNext(&pIt, &pV, true);
               subDataJb = JsonbValueToJsonb(&v);
               subSchemaJb = JsonbValueToJsonb(&pV);
               isPropertyValid = _is_jsonb_valid(subSchemaJb, subDataJb, root_schema);
               if (DEBUG_IS_JSONB_VALID && !isPropertyValid) elog(INFO, "property is not valid %*.*s", k.val.string.len, k.val.string.len, k.val.string.val);
               isValid = isValid && isPropertyValid;
               r = JsonbIteratorNext(&it, &k, true);
               pR = JsonbIteratorNext(&pIt, &pK, true);
            }
        }
        return isValid;
        /**
        * The last case is when patternProperties is defined. This case is highly unoptimal.
        * We iterate over all properties of object. We check against all keys of patterProperties for the regex.
        * Then we check if the property is present in propertiesJb.
        * If neither of the previous happened, then we check against additionalProperties
        */
    } else {
        JsonbValue k, ppK, v, ppV;
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
            Jsonb * subDataJbv;
            r = JsonbIteratorNext(&it, &k, true);
            if (r == WJB_END_OBJECT)
                break;
            r = JsonbIteratorNext(&it, &v, true);
            subDataJbv = JsonbValueToJsonb(&v);
            ppIt = JsonbIteratorInit(&patternPropertiesJb->root);
            ppR = JsonbIteratorNext(&ppIt, &ppK, true);
            Assert(ppR = WJB_BEGIN_OBJECT);
            while (isValid) {
                bool keyMatches;
                ppR = JsonbIteratorNext(&ppIt, &ppK, true);
                if (ppR == WJB_END_OBJECT)
                    break;
                ppR = JsonbIteratorNext(&ppIt, &ppV, true);
                keyMatches = DatumGetBool(DirectFunctionCall2Coll(textregexeq, DEFAULT_COLLATION_OID,
                                PointerGetDatum(cstring_to_text_with_len(k.val.string.val, k.val.string.len)),
                                PointerGetDatum(cstring_to_text_with_len(ppK.val.string.val, ppK.val.string.len))));
                if (DEBUG_IS_JSONB_VALID) elog(INFO, keyMatches ? "regex matched" : "regex did not matched");
                if (keyMatches) {
                       Jsonb * subSchemaJb;
                        subSchemaJb = JsonbValueToJsonb(&ppV);
                        isValid = isValid && _is_jsonb_valid(subSchemaJb, subDataJbv, root_schema);
                        keyMatched = true;
                }
            }
            if (propertiesJbv != NULL && propertiesJb != NULL) {
                JsonbValue * subSchemaJbv;
                Jsonb * subSchemaJb;

                subSchemaJbv = findJsonbValueFromContainer(&propertiesJb->root, JB_FOBJECT, &k);
                if (subSchemaJbv != NULL) {
                    subSchemaJb = JsonbValueToJsonb(subSchemaJbv);
                    isValid = isValid && _is_jsonb_valid(subSchemaJb, subDataJbv, root_schema);
                    keyMatched = true;
                }
            }
            if (keyMatched != true && additionalPropertiesJbv != NULL) {
                if (additionalPropertiesJbv->type == jbvBool && additionalPropertiesJbv->val.boolean == false) {
                    isValid = false;
                } else if (JB_ROOT_IS_OBJECT(additionalPropertiesJb)) {
                    isValid = isValid && _is_jsonb_valid(additionalPropertiesJb, subDataJbv, root_schema);
                }
            }
        }
        return isValid;
    }
}

static bool validate_items (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema) {
    JsonbValue * itemsJbv, * additionalItemsJbv;
    bool isValid = true;
    Jsonb * itemsJb;
    JsonbIterator * it;
    JsonbIteratorToken r;
    JsonbValue itemJbv;
    if (!root_is_really_an_array(dataJb)) return isValid;
    itemsJbv = get_jbv_from_key(schemaJb, "items");

    if (itemsJbv == NULL)
        return true;

    additionalItemsJbv = get_jbv_from_key(schemaJb, "additionalItems");
    itemsJb = JsonbValueToJsonb(itemsJbv);

    if (JB_ROOT_IS_OBJECT(itemsJb)) {
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
            isItemValid = _is_jsonb_valid(itemsJb, subDataJb, root_schema);
            if (DEBUG_IS_JSONB_VALID && !isItemValid) elog(INFO, "Item is not valid");
            isValid = isValid && isItemValid;
        }
    } else if (root_is_really_an_array(itemsJb)) {
        JsonbIterator *schemaIt;
        JsonbIteratorToken schemaR;
        JsonbValue schemaJbv;
        Jsonb * additionalItemsJb;
        bool additionalItemsBuilt = false;
        bool isItemsObjectFinished = false;
        if (DEBUG_IS_JSONB_VALID) elog(INFO, "Items is array");
        it = JsonbIteratorInit(&dataJb->root);
        r = JsonbIteratorNext(&it, &itemJbv, true);

        schemaIt = JsonbIteratorInit(&itemsJb->root);
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
                if (DEBUG_IS_JSONB_VALID && !isItemValid) elog(INFO, "Item is not valid");
            } else {
                Jsonb * subDataJb;
                if (DEBUG_IS_JSONB_VALID) elog(INFO, "Validating against additionalItems");
                // No more condition on items
                if (additionalItemsJbv == NULL) {
                    break;
                } else if (additionalItemsJbv->type == jbvBool) {
                    isValid = additionalItemsJbv->val.boolean;
                    if (DEBUG_IS_JSONB_VALID && !isValid) elog(INFO, "There were additional items");
                    break;
                } else if (additionalItemsBuilt) {
                    subDataJb = JsonbValueToJsonb(&itemJbv);
                    isItemValid = _is_jsonb_valid(additionalItemsJb, subDataJb, root_schema);
                } else if (additionalItemsJbv->type == jbvBinary) {
                    additionalItemsBuilt = true;
                    additionalItemsJb = JsonbValueToJsonb(additionalItemsJbv);
                    subDataJb = JsonbValueToJsonb(&itemJbv);
                    isItemValid = _is_jsonb_valid(additionalItemsJb, subDataJb, root_schema);
                    if (DEBUG_IS_JSONB_VALID && !isItemValid) elog(INFO, "Item does not validate against additionalItems");
                } else {
                    break;
                }
            }
            isValid = isValid && isItemValid;
        }
    } else {
        ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE), errmsg("Items must be array or object")));
    }

    return isValid;
}

static bool validate_min (Jsonb * schemaJb, Jsonb * dataJb)
{
    JsonbIterator *it;
    JsonbValue	v;
    JsonbValue *minJbv, *exclusiveMinJbv;
    // bool isValid = true;
    if (!is_type_correct(dataJb, "number", 6))
        return true;

    minJbv = get_jbv_from_key(schemaJb, "minimum");

    if (minJbv == NULL || minJbv->type != jbvNumeric) {
        return true;
    }
    it = JsonbIteratorInit(&dataJb->root);
    // scalar is saved as array of one element
    (void) JsonbIteratorNext(&it, &v, true);
    Assert(v.type == jbvArray);
    (void) JsonbIteratorNext(&it, &v, true);

    if (DatumGetBool(DirectFunctionCall2(numeric_lt, PointerGetDatum(v.val.numeric), PointerGetDatum(minJbv->val.numeric)))) {
        if (DEBUG_IS_JSONB_VALID) elog(INFO, "Value is not bigger than minimum");
        return false;
    }

    exclusiveMinJbv = get_jbv_from_key(schemaJb, "exclusiveMinimum");

    if (exclusiveMinJbv == NULL || exclusiveMinJbv->type != jbvBool || exclusiveMinJbv->val.boolean != true)
        return true;

    if (DatumGetBool(DirectFunctionCall2(numeric_eq, PointerGetDatum(v.val.numeric), PointerGetDatum(minJbv->val.numeric)))) {
        if (DEBUG_IS_JSONB_VALID) elog(INFO, "Value is not strictly bigger than minimum");
        return false;
    }
    return true;
}

static bool validate_max (Jsonb * schemaJb, Jsonb * dataJb)
{
    JsonbIterator *it;
    JsonbValue	v;
    JsonbValue *maxJbv, *exclusiveMaxJbv;
    // bool isValid = true;
    if (!is_type_correct(dataJb, "number", 6))
        return true;


    maxJbv = get_jbv_from_key(schemaJb, "maximum");

    if (maxJbv == NULL || maxJbv->type != jbvNumeric)
        return true;

    it = JsonbIteratorInit(&dataJb->root);
    // scalar is saved as array of one element
    (void) JsonbIteratorNext(&it, &v, true);
    Assert(v.type == jbvArray);
    (void) JsonbIteratorNext(&it, &v, true);

    if (DatumGetBool(DirectFunctionCall2(numeric_gt, PointerGetDatum(v.val.numeric), PointerGetDatum(maxJbv->val.numeric)))) {
        if (DEBUG_IS_JSONB_VALID) elog(INFO, "Value is not smaller than maximum");
        return false;
    }

    exclusiveMaxJbv = get_jbv_from_key(schemaJb, "exclusiveMaximum");

    if (exclusiveMaxJbv == NULL || exclusiveMaxJbv->type != jbvBool || exclusiveMaxJbv->val.boolean != true)
        return true;

    if (DatumGetBool(DirectFunctionCall2(numeric_eq, PointerGetDatum(v.val.numeric), PointerGetDatum(maxJbv->val.numeric)))) {
        if (DEBUG_IS_JSONB_VALID) elog(INFO, "Value is not strictly smaller than maximum");
        return false;
    }
    return true;
}


static bool validate_any_of (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema)
{
    JsonbValue * propertyJbv;
    JsonbIterator *it;
    JsonbValue v;
    JsonbIteratorToken r;
    Jsonb * anyOfJb;
    bool isValid = false;
    propertyJbv = get_jbv_from_key(schemaJb, "anyOf");
    // It cannot be array
    if (propertyJbv == NULL || propertyJbv->type != jbvBinary) {
        return true;
    }
    anyOfJb = JsonbValueToJsonb(propertyJbv);
    if (!root_is_really_an_array(anyOfJb)) {
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
    JsonbValue * propertyJbv;
    JsonbIterator *it;
    JsonbValue v;
    JsonbIteratorToken r;
    Jsonb * allOfJb;
    bool isValid = true;
    propertyJbv = get_jbv_from_key(schemaJb, "allOf");
    // It cannot be array
    if (propertyJbv == NULL || propertyJbv->type != jbvBinary) {
        return true;
    }
    allOfJb = JsonbValueToJsonb(propertyJbv);
    if (!root_is_really_an_array(allOfJb)) {
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
    JsonbValue * propertyJbv;
    JsonbIterator *it;
    JsonbValue v;
    JsonbIteratorToken r;
    Jsonb * oneOfJb;
    int countValid = 0;
    propertyJbv = get_jbv_from_key(schemaJb, "oneOf");
    // It cannot be array
    if (propertyJbv == NULL || propertyJbv->type != jbvBinary) {
        return true;
    }
    oneOfJb = JsonbValueToJsonb(propertyJbv);
    if (!root_is_really_an_array(oneOfJb)) {
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

/*
* Unique items is far from optimal O(n2).
*/
static bool validate_unique_items (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema)
{
        JsonbValue * propertyJbv;
        JsonbIterator *it;
        JsonbValue v;
        JsonbIteratorToken r;
        bool isValid = true;
        int i = 0;
        propertyJbv = get_jbv_from_key(schemaJb, "uniqueItems");
        // It cannot be array
        if (!root_is_really_an_array(dataJb) || propertyJbv == NULL || propertyJbv->type != jbvBool || propertyJbv->val.boolean == false) {
            return true;
        }
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
            _unused(r2);
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

static bool validate_ref (JsonbValue * refJbv, Jsonb * dataJb, Jsonb * root_schema)
{
    ArrayType *path;
    Datum *pathtext;
    JsonbValue * refSchemaJbv = NULL;
    Jsonb * refSchemaJb;
    bool *pathnulls;
    bool have_object = true, have_array = false;
    int npath;
    int i;
    JsonbContainer * container;
    Assert(refJbv != NULL);
    if (refJbv->type != jbvString)
    {
        ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE), errmsg("$ref must be a string")));
    }

    path = DatumGetArrayTypeP(DirectFunctionCall2Coll(
        regexp_split_to_array,
        DEFAULT_COLLATION_OID,
        PointerGetDatum(cstring_to_text_with_len(refJbv->val.string.val, refJbv->val.string.len)),
        PointerGetDatum(cstring_to_text("/"))));
    /*
    * Code from here is very similar to get_jsonb_path_all
    */
    deconstruct_array(path, TEXTOID, -1, false, 'i',
                            &pathtext, &pathnulls, &npath);
    if (npath <= 0)
        ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE), errmsg("$ref must not be an empty string"))); // Not sure if npath = 0 can actually happen. Even for empty strings
    // We only support refs anchored at root
    if (!DatumGetBool(DirectFunctionCall2Coll(texteq,
            DEFAULT_COLLATION_OID,
            PointerGetDatum((const void *)((Datum *)pathtext)[0]), PointerGetDatum(cstring_to_text("#")))))
        ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE), errmsg("$ref must be anchored at root")));
    Assert(JB_ROOT_IS_OBJECT(root_schema));
    container = &root_schema->root;

    for (i = 1; i < npath; i++) {
        text * route;

        // TODO textregexreplace_noopt replaces only first instance. We should replace all instances
        route = DatumGetTextP(DirectFunctionCall3Coll(
            textregexreplace_noopt,
            DEFAULT_COLLATION_OID,
            DirectFunctionCall3Coll(
                textregexreplace_noopt,
                DEFAULT_COLLATION_OID,
                PointerGetDatum((const void *)((Datum *)pathtext)[i]),
                CStringGetTextDatum("~1"),
                CStringGetTextDatum("/")),
            CStringGetTextDatum("~0"),
            CStringGetTextDatum("~")));
        if (have_object) {
            JsonbValue k;
            k.type = jbvString;
            k.val.string.val = VARDATA(route);
            k.val.string.len = VARSIZE(route) - VARHDRSZ;
            refSchemaJbv = findJsonbValueFromContainer(container, JB_FOBJECT, &k);
        } else if (have_array) {
            long		lindex;
            			uint32		index;
            			char	   *indextext = TextDatumGetCString((Datum)route);
            			char	   *endptr;

            			errno = 0;
            			lindex = strtol(indextext, &endptr, 10);
            			if (endptr == indextext || *endptr != '\0' || errno != 0 ||
            				lindex > INT_MAX || lindex < INT_MIN)
            				return true;

            			if (lindex >= 0)
            			{
            				index = (uint32) lindex;
            			}
            			else
            			{
            				/* Handle negative subscript */
            				uint32		nelements;

            				/* Container must be array, but make sure */
            				if (!JsonContainerIsArray(container))
            					elog(ERROR, "not a jsonb array");

            				nelements = JsonContainerSize(container);

            				if (-lindex > nelements)
                                ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE), errmsg("$ref wrong path, index out of bounds")));
            				else
            					index = nelements + lindex;
            			}

            			refSchemaJbv = getIthJsonbValueFromContainer(container, index);
        } else {
            // scalar access
            ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE), errmsg("$ref must point to a schema, not to a scalar")));
        }
        if (refSchemaJbv == NULL) {
            ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE), errmsg("Missing references $ref")));
        }
        if (i == npath -1 ) {
            // No need to compute have_array or have_object now
            break;
        }

        if (refSchemaJbv->type == jbvBinary)
        {
            JsonbIterator *it = JsonbIteratorInit((JsonbContainer *) refSchemaJbv->val.binary.data);
            JsonbIteratorToken r;
            JsonbValue tv;

            r = JsonbIteratorNext(&it, &tv, true);
            container = (JsonbContainer *) refSchemaJbv->val.binary.data;
            have_object = r == WJB_BEGIN_OBJECT;
            have_array = r == WJB_BEGIN_ARRAY;
        }
        else
        {
            // Not sure when this can happen
            elog(INFO, "Type in $ref was not jbvBinary");
            have_object = refSchemaJbv->type == jbvObject;
            have_array = refSchemaJbv->type == jbvArray;
        }
    }

    refSchemaJb = npath == 1 ? root_schema : JsonbValueToJsonb(refSchemaJbv);
    return _is_jsonb_valid(refSchemaJb, dataJb, root_schema);
}


static bool validate_enum (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema)
{
        JsonbValue * propertyJbv;
        Jsonb * enumJb;
        JsonbIterator *it;
        JsonbValue v;
        JsonbIteratorToken r;
        bool isValid = false;
        propertyJbv = get_jbv_from_key(schemaJb, "enum");
        if (propertyJbv == NULL || propertyJbv->type != jbvBinary)
        {
            return true;
        }
        enumJb = JsonbValueToJsonb(propertyJbv);
        if (!root_is_really_an_array(enumJb))
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
    JsonbValue *minLenghtJbv, *maxLengthJbv;
    bool isValid = true;
    // bool isValid = true;
    if (!is_type_correct(dataJb, "string", 6))
        return true;

    it = JsonbIteratorInit(&dataJb->root);
    // scalar is saved as array of one element
    (void) JsonbIteratorNext(&it, &v, true);
    Assert(v.type == jbvArray);
    (void) JsonbIteratorNext(&it, &v, true);


    minLenghtJbv = get_jbv_from_key(schemaJb, "minLength");

    if (minLenghtJbv != NULL && minLenghtJbv->type == jbvNumeric) {
        int length = DatumGetInt32(DirectFunctionCall1(textlen, PointerGetDatum(cstring_to_text_with_len(v.val.string.val, v.val.string.len))));

        if (DEBUG_IS_JSONB_VALID) elog(INFO, "Length is %d", length);
        isValid = isValid && DatumGetBool(DirectFunctionCall2(numeric_ge, DirectFunctionCall1(int4_numeric, length), PointerGetDatum(minLenghtJbv->val.numeric)));
    }

    maxLengthJbv = get_jbv_from_key(schemaJb, "maxLength");

    if (maxLengthJbv != NULL && maxLengthJbv->type == jbvNumeric) {
        int length = DatumGetInt32(DirectFunctionCall1(textlen, PointerGetDatum(cstring_to_text_with_len(v.val.string.val, v.val.string.len))));
        isValid = isValid && DatumGetBool(DirectFunctionCall2(numeric_le, DirectFunctionCall1(int4_numeric, length), PointerGetDatum(maxLengthJbv->val.numeric)));
    }
    return isValid;
}

static bool validate_not (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema)
{
    JsonbValue * propertyJbv;
    Jsonb * notJb;
    propertyJbv = get_jbv_from_key(schemaJb, "not");
    // It cannot be array
    if (propertyJbv == NULL || propertyJbv->type != jbvBinary) {
        return true;
    }
    notJb = JsonbValueToJsonb(propertyJbv);
    if (!JB_ROOT_IS_OBJECT(notJb)) {
        return true;
    }
    return !_is_jsonb_valid(notJb, dataJb, root_schema);
}

static bool validate_num_properties (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema)
{
    JsonbValue * maxPropertiesJbv, * minPropertiesJbv;
    JsonbIterator *it;
    JsonbIteratorToken r;
    JsonbValue v;
    bool isValid = true;

    //int numProperties = 0;

    if (!JB_ROOT_IS_OBJECT(dataJb))
        return true;

    minPropertiesJbv = get_jbv_from_key(schemaJb, "minProperties");
    maxPropertiesJbv = get_jbv_from_key(schemaJb, "maxProperties");

    if (minPropertiesJbv == NULL && maxPropertiesJbv == NULL)
        return true;

    it = JsonbIteratorInit(&dataJb->root);
    r = JsonbIteratorNext(&it, &v, true);
    Assert(r == WJB_BEGIN_OBJECT);
    _unused(r);
    Assert(v.type == jbvObject);

    if (minPropertiesJbv != NULL && minPropertiesJbv->type == jbvNumeric)
        isValid = isValid && DatumGetBool(DirectFunctionCall2(numeric_ge, DirectFunctionCall1(int4_numeric, v.val.object.nPairs), PointerGetDatum(minPropertiesJbv->val.numeric)));
    if (maxPropertiesJbv != NULL && maxPropertiesJbv->type == jbvNumeric)
        isValid = isValid && DatumGetBool(DirectFunctionCall2(numeric_le, DirectFunctionCall1(int4_numeric, v.val.object.nPairs), PointerGetDatum(maxPropertiesJbv->val.numeric)));
    return isValid;
}

static bool validate_num_items (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema)
{
    JsonbValue * maxItemsJbv, * minItemsJbv;
    JsonbIterator *it;
    JsonbIteratorToken r;
    JsonbValue v;
    bool isValid = true;

    //int numItems = 0;

    if (!root_is_really_an_array(dataJb))
        return true;

    minItemsJbv = get_jbv_from_key(schemaJb, "minItems");
    maxItemsJbv = get_jbv_from_key(schemaJb, "maxItems");

    if (minItemsJbv == NULL && maxItemsJbv == NULL)
        return true;

    it = JsonbIteratorInit(&dataJb->root);
    r = JsonbIteratorNext(&it, &v, true);
    Assert(r == WJB_BEGIN_ARRAY);
    _unused(r);
    Assert(v.type == jbvArray);

    if (minItemsJbv != NULL && minItemsJbv->type == jbvNumeric)
        isValid = isValid && DatumGetBool(DirectFunctionCall2(numeric_ge, DirectFunctionCall1(int4_numeric, v.val.array.nElems), PointerGetDatum(minItemsJbv->val.numeric)));
    if (maxItemsJbv != NULL && maxItemsJbv->type == jbvNumeric)
        isValid = isValid && DatumGetBool(DirectFunctionCall2(numeric_le, DirectFunctionCall1(int4_numeric, v.val.array.nElems), PointerGetDatum(maxItemsJbv->val.numeric)));
    return isValid;
}

// TODO validate against malformed types
static bool validate_dependencies (Jsonb * schemaJb, Jsonb * dataJb, Jsonb * root_schema)
{
    JsonbValue *dependenciesJbv;
    Jsonb *dependenciesJb;
    JsonbIterator * it;
    JsonbValue k, v;
    JsonbIteratorToken r;
    bool isValid = true;

    if (!JB_ROOT_IS_OBJECT(dataJb))
        return true;

    dependenciesJbv = get_jbv_from_key(schemaJb, "dependencies");
    if (dependenciesJbv == NULL || dependenciesJbv->type != jbvBinary)
        return true;

    dependenciesJb = JsonbValueToJsonb(dependenciesJbv);
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

                if (root_is_really_an_array(dependencyJb)) {
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
    JsonbValue *patternJbv;
    bool isValid = true;
    // bool isValid = true;
    if (!is_type_correct(dataJb, "string", 6))
        return true;
    patternJbv = get_jbv_from_key(schemaJb, "pattern");
    if (patternJbv == NULL) {
        return true;
    }
	it = JsonbIteratorInit(&dataJb->root);
    // scalar is saved as array of one element
    (void) JsonbIteratorNext(&it, &v, true);
    Assert(v.type == jbvArray);
    (void) JsonbIteratorNext(&it, &v, true);


    if (patternJbv->type == jbvString) {
        return DatumGetBool(DirectFunctionCall2Coll(textregexeq, DEFAULT_COLLATION_OID,
            PointerGetDatum(cstring_to_text_with_len(v.val.string.val, v.val.string.len)),
            PointerGetDatum(cstring_to_text_with_len(patternJbv->val.string.val, patternJbv->val.string.len))));
    }
    return isValid;
}

static bool validate_multiple_of (Jsonb * schemaJb, Jsonb * dataJb)
{
    JsonbIterator *it;
    JsonbValue	v;
    JsonbValue *multipleOfJbv;
    Numeric dividend;
    // bool isValid = true;
    if (!is_type_correct(dataJb, "number", 6))
        return true;


    multipleOfJbv = get_jbv_from_key(schemaJb, "multipleOf");

    if (multipleOfJbv == NULL || multipleOfJbv->type != jbvNumeric)
        return true;

    it = JsonbIteratorInit(&dataJb->root);
    // scalar is saved as array of one element
    (void) JsonbIteratorNext(&it, &v, true);
    Assert(v.type == jbvArray);
    (void) JsonbIteratorNext(&it, &v, true);

    dividend = DatumGetNumeric(DirectFunctionCall2(numeric_div, PointerGetDatum(v.val.numeric), PointerGetDatum(multipleOfJbv->val.numeric)));
    return DatumGetBool(DirectFunctionCall2(
                                numeric_eq,
                                PointerGetDatum(dividend),
                                DirectFunctionCall1(numeric_floor, PointerGetDatum(dividend))));
}



static JsonbValue * get_jbv_from_key (Jsonb * in, const char * key)
{
    JsonbValue propertyKey;
    JsonbValue * propertyJbv;
    text* keyText;
    propertyKey.type = jbvString;
    keyText = cstring_to_text(key);
    propertyKey.val.string.val = VARDATA_ANY(keyText);
    propertyKey.val.string.len = VARSIZE_ANY_EXHDR(keyText);
    // findJsonbValueFromContainer returns palloced value
    propertyJbv = findJsonbValueFromContainer(&in->root, JB_FOBJECT, &propertyKey);
    return propertyJbv;
}

