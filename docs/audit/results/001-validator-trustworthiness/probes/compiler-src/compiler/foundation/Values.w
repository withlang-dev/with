// Wave 1 foundations: internable value keys.

use compiler.foundation.Ids
extern fn with_str_clone_ref(s: &str) -> str

pub fn VALUE_KEY_INVALID -> i32: 0
pub fn VALUE_KEY_INT -> i32: 1
pub fn VALUE_KEY_BOOL -> i32: 2
pub fn VALUE_KEY_STRING -> i32: 3
pub fn VALUE_KEY_TYPE_MARKER -> i32: 4

pub type ValueKey {
    tag: i32,
    int_value: i32,
    text_value: str,
    type_ref: i32,
}
// #747: str field — owned, non-Copy now; moves/clones spell intent.

pub fn value_key_invalid -> ValueKey:
    ValueKey {
        tag: VALUE_KEY_INVALID(),
        int_value: 0,
        text_value: "",
        type_ref: -1,
    }

pub fn value_key_int(v: i32) -> ValueKey:
    ValueKey {
        tag: VALUE_KEY_INT(),
        int_value: v,
        text_value: "",
        type_ref: -1,
    }

pub fn value_key_bool(v: bool) -> ValueKey:
    ValueKey {
        tag: VALUE_KEY_BOOL(),
        int_value: if v: 1 else: 0,
        text_value: "",
        type_ref: -1,
    }

pub fn value_key_string(v: &str) -> ValueKey:
    ValueKey {
        tag: VALUE_KEY_STRING(),
        int_value: 0,
        text_value: with_str_clone_ref(v),
        type_ref: -1,
    }

pub fn value_key_type_marker(ty: TypeId) -> ValueKey:
    ValueKey {
        tag: VALUE_KEY_TYPE_MARKER(),
        int_value: 0,
        text_value: "",
        type_ref: type_id_raw(ty),
    }

pub fn value_key_to_string(key: &ValueKey) -> str:
    if key.tag == VALUE_KEY_INT():
        return f"int:{key.int_value}"
    if key.tag == VALUE_KEY_BOOL():
        return f"bool:{key.int_value}"
    if key.tag == VALUE_KEY_STRING():
        var out = "str:"
        out = out ++ key.text_value
        return out
    if key.tag == VALUE_KEY_TYPE_MARKER():
        return f"ty:{key.type_ref}"
    "invalid"

// #747: explicit owned copy — ValueKey's text_value is an owned str now.
pub fn value_key_clone(key: &ValueKey) -> ValueKey:
    ValueKey { tag: key.tag, int_value: key.int_value, text_value: with_str_clone_ref(key.text_value), type_ref: key.type_ref }
