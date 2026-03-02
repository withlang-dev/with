// Wave 1 foundations: internable type keys.
//
// Canonical keys are encoded to deterministic strings for HashMap lookups.

use compiler.foundation.Ids

extern fn int_to_string(n: i32) -> str

fn TYPE_KEY_INVALID -> i32: 0
fn TYPE_KEY_NAMED -> i32: 1
fn TYPE_KEY_PTR -> i32: 2
fn TYPE_KEY_SLICE -> i32: 3
fn TYPE_KEY_ARRAY -> i32: 4
fn TYPE_KEY_TUPLE2 -> i32: 5
fn TYPE_KEY_OPTIONAL -> i32: 6
fn TYPE_KEY_RESULT2 -> i32: 7

type TypeKey = {
    tag: i32,
    name: str,
    arg0: i32,
    arg1: i32,
    flags: i32,
}

fn type_key_invalid -> TypeKey:
    TypeKey {
        tag: TYPE_KEY_INVALID(),
        name: "",
        arg0: 0,
        arg1: 0,
        flags: 0,
    }

fn type_key_named(name: str) -> TypeKey:
    TypeKey {
        tag: TYPE_KEY_NAMED(),
        name,
        arg0: 0,
        arg1: 0,
        flags: 0,
    }

fn type_key_ptr(inner: TypeId, is_mut: bool) -> TypeKey:
    TypeKey {
        tag: TYPE_KEY_PTR(),
        name: "",
        arg0: type_id_raw(inner),
        arg1: 0,
        flags: if is_mut: 1 else: 0,
    }

fn type_key_slice(inner: TypeId) -> TypeKey:
    TypeKey {
        tag: TYPE_KEY_SLICE(),
        name: "",
        arg0: type_id_raw(inner),
        arg1: 0,
        flags: 0,
    }

fn type_key_array(inner: TypeId, count: i32) -> TypeKey:
    TypeKey {
        tag: TYPE_KEY_ARRAY(),
        name: "",
        arg0: type_id_raw(inner),
        arg1: count,
        flags: 0,
    }

fn type_key_tuple2(a: TypeId, b: TypeId) -> TypeKey:
    TypeKey {
        tag: TYPE_KEY_TUPLE2(),
        name: "",
        arg0: type_id_raw(a),
        arg1: type_id_raw(b),
        flags: 0,
    }

fn type_key_optional(inner: TypeId) -> TypeKey:
    TypeKey {
        tag: TYPE_KEY_OPTIONAL(),
        name: "",
        arg0: type_id_raw(inner),
        arg1: 0,
        flags: 0,
    }

fn type_key_result2(ok_ty: TypeId, err_ty: TypeId) -> TypeKey:
    TypeKey {
        tag: TYPE_KEY_RESULT2(),
        name: "",
        arg0: type_id_raw(ok_ty),
        arg1: type_id_raw(err_ty),
        flags: 0,
    }

fn type_key_to_string(key: TypeKey) -> str:
    if key.tag == TYPE_KEY_NAMED():
        return "named:" ++ key.name
    if key.tag == TYPE_KEY_PTR():
        return "ptr:" ++ int_to_string(key.arg0) ++ ":" ++ int_to_string(key.flags)
    if key.tag == TYPE_KEY_SLICE():
        return "slice:" ++ int_to_string(key.arg0)
    if key.tag == TYPE_KEY_ARRAY():
        return "array:" ++ int_to_string(key.arg0) ++ ":" ++ int_to_string(key.arg1)
    if key.tag == TYPE_KEY_TUPLE2():
        return "tuple2:" ++ int_to_string(key.arg0) ++ ":" ++ int_to_string(key.arg1)
    if key.tag == TYPE_KEY_OPTIONAL():
        return "opt:" ++ int_to_string(key.arg0)
    if key.tag == TYPE_KEY_RESULT2():
        return "result2:" ++ int_to_string(key.arg0) ++ ":" ++ int_to_string(key.arg1)
    "invalid"
