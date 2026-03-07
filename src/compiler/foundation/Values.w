// Wave 1 foundations: internable value keys.

use compiler.foundation.Ids

extern fn int_to_string(n: i32) -> str

fn VALUE_KEY_INVALID -> i32: 0
fn VALUE_KEY_INT -> i32: 1
fn VALUE_KEY_BOOL -> i32: 2
fn VALUE_KEY_STRING -> i32: 3
fn VALUE_KEY_TYPE_MARKER -> i32: 4

type ValueKey = {
    tag: i32,
    int_value: i32,
    text_value: str,
    type_ref: i32,
}

fn value_key_invalid -> ValueKey:
    ValueKey {
        tag: VALUE_KEY_INVALID(),
        int_value: 0,
        text_value: "",
        type_ref: -1,
    }

fn value_key_int(v: i32) -> ValueKey:
    ValueKey {
        tag: VALUE_KEY_INT(),
        int_value: v,
        text_value: "",
        type_ref: -1,
    }

fn value_key_bool(v: bool) -> ValueKey:
    ValueKey {
        tag: VALUE_KEY_BOOL(),
        int_value: if v: 1 else: 0,
        text_value: "",
        type_ref: -1,
    }

fn value_key_string(v: str) -> ValueKey:
    ValueKey {
        tag: VALUE_KEY_STRING(),
        int_value: 0,
        text_value: v,
        type_ref: -1,
    }

fn value_key_type_marker(ty: TypeId) -> ValueKey:
    ValueKey {
        tag: VALUE_KEY_TYPE_MARKER(),
        int_value: 0,
        text_value: "",
        type_ref: type_id_raw(ty),
    }

fn value_key_to_string(key: ValueKey) -> str:
    if key.tag == VALUE_KEY_INT():
        var out = "int:"
        out = out ++ int_to_string(key.int_value)
        return out
    if key.tag == VALUE_KEY_BOOL():
        var out = "bool:"
        out = out ++ int_to_string(key.int_value)
        return out
    if key.tag == VALUE_KEY_STRING():
        var out = "str:"
        out = out ++ key.text_value
        return out
    if key.tag == VALUE_KEY_TYPE_MARKER():
        var out = "ty:"
        out = out ++ int_to_string(key.type_ref)
        return out
    "invalid"
