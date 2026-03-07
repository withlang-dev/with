// Wave 1 foundations: internable type keys.
//
// Canonical keys are encoded to deterministic strings for HashMap lookups.

use std.prelude_core

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
fn TYPE_KEY_REF -> i32: 8
fn TYPE_KEY_FN_SIG -> i32: 9
fn TYPE_KEY_TRAIT_OBJECT -> i32: 10
fn TYPE_KEY_GENERIC_PARAM -> i32: 11
fn TYPE_KEY_GENERIC_APPLY2 -> i32: 12
fn TYPE_KEY_TUPLEN -> i32: 13

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

fn type_key_ref(inner: TypeId, is_mut: bool) -> TypeKey:
    TypeKey {
        tag: TYPE_KEY_REF(),
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

fn type_key_pack1(a: TypeId) -> str:
    int_to_string(type_id_raw(a))

fn type_key_pack2(a: TypeId, b: TypeId) -> str:
    var out = int_to_string(type_id_raw(a))
    out = out ++ ","
    out = out ++ int_to_string(type_id_raw(b))
    out

fn type_key_pack3(a: TypeId, b: TypeId, c: TypeId) -> str:
    var out = int_to_string(type_id_raw(a))
    out = out ++ ","
    out = out ++ int_to_string(type_id_raw(b))
    out = out ++ ","
    out = out ++ int_to_string(type_id_raw(c))
    out

fn type_key_tuplen(elem_pack: str, count: i32) -> TypeKey:
    TypeKey {
        tag: TYPE_KEY_TUPLEN(),
        name: elem_pack,
        arg0: count,
        arg1: 0,
        flags: 0,
    }

fn type_key_fn_sig(param_pack: str, ret: TypeId, arity: i32, is_variadic: bool) -> TypeKey:
    TypeKey {
        tag: TYPE_KEY_FN_SIG(),
        name: param_pack,
        arg0: type_id_raw(ret),
        arg1: arity,
        flags: if is_variadic: 1 else: 0,
    }

fn type_key_trait_object(trait_name: str) -> TypeKey:
    TypeKey {
        tag: TYPE_KEY_TRAIT_OBJECT(),
        name: trait_name,
        arg0: 0,
        arg1: 0,
        flags: 0,
    }

fn type_key_generic_param(param_name: str, index: i32) -> TypeKey:
    TypeKey {
        tag: TYPE_KEY_GENERIC_PARAM(),
        name: param_name,
        arg0: index,
        arg1: 0,
        flags: 0,
    }

fn type_key_generic_apply2(base_name: str, a0: TypeId, a1: TypeId, arg_count: i32) -> TypeKey:
    TypeKey {
        tag: TYPE_KEY_GENERIC_APPLY2(),
        name: base_name,
        arg0: type_id_raw(a0),
        arg1: type_id_raw(a1),
        flags: arg_count,
    }

fn type_key_to_string(key: TypeKey) -> str:
    if key.tag == TYPE_KEY_NAMED():
        var out = "named:"
        out = out ++ key.name
        return out
    if key.tag == TYPE_KEY_PTR():
        var out = "ptr:"
        out = out ++ int_to_string(key.arg0)
        out = out ++ ":"
        out = out ++ int_to_string(key.flags)
        return out
    if key.tag == TYPE_KEY_REF():
        var out = "ref:"
        out = out ++ int_to_string(key.arg0)
        out = out ++ ":"
        out = out ++ int_to_string(key.flags)
        return out
    if key.tag == TYPE_KEY_SLICE():
        var out = "slice:"
        out = out ++ int_to_string(key.arg0)
        return out
    if key.tag == TYPE_KEY_ARRAY():
        var out = "array:"
        out = out ++ int_to_string(key.arg0)
        out = out ++ ":"
        out = out ++ int_to_string(key.arg1)
        return out
    if key.tag == TYPE_KEY_TUPLE2():
        var out = "tuple2:"
        out = out ++ int_to_string(key.arg0)
        out = out ++ ":"
        out = out ++ int_to_string(key.arg1)
        return out
    if key.tag == TYPE_KEY_TUPLEN():
        var out = "tuplen:"
        out = out ++ int_to_string(key.arg0)
        out = out ++ ":"
        out = out ++ key.name
        return out
    if key.tag == TYPE_KEY_OPTIONAL():
        var out = "opt:"
        out = out ++ int_to_string(key.arg0)
        return out
    if key.tag == TYPE_KEY_RESULT2():
        var out = "result2:"
        out = out ++ int_to_string(key.arg0)
        out = out ++ ":"
        out = out ++ int_to_string(key.arg1)
        return out
    if key.tag == TYPE_KEY_FN_SIG():
        var out = "fnsig:"
        out = out ++ key.name
        out = out ++ "->"
        out = out ++ int_to_string(key.arg0)
        out = out ++ ":arity="
        out = out ++ int_to_string(key.arg1)
        out = out ++ ":var="
        out = out ++ int_to_string(key.flags)
        return out
    if key.tag == TYPE_KEY_TRAIT_OBJECT():
        var out = "traitobj:"
        out = out ++ key.name
        return out
    if key.tag == TYPE_KEY_GENERIC_PARAM():
        var out = "gparam:"
        out = out ++ key.name
        out = out ++ ":"
        out = out ++ int_to_string(key.arg0)
        return out
    if key.tag == TYPE_KEY_GENERIC_APPLY2():
        var out = "gapply2:"
        out = out ++ key.name
        out = out ++ ":"
        out = out ++ int_to_string(key.arg0)
        out = out ++ ":"
        out = out ++ int_to_string(key.arg1)
        out = out ++ ":n="
        out = out ++ int_to_string(key.flags)
        return out
    "invalid"
