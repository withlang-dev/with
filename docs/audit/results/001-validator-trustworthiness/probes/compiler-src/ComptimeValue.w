use Sema
use CapabilityRegistry

extern fn with_str_clone_ref(s: &str) -> str
extern fn with_str_eq_ref(a: &str, b: &str) -> i32
extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8) -> Unit

enum ComptimeValueKind: i32:
    CV_INVALID = 0
    CV_VOID = 1
    CV_INT = 2
    CV_BOOL = 3
    CV_STR = 4
    CV_ARRAY = 5
    CV_TUPLE = 6
    CV_RANGE = 7
    CV_STRUCT = 8
    CV_VEC = 9
    CV_MAP = 10
    CV_CAPABILITY = 11
    CV_FN = 12
    CV_ENUM = 13
    CV_BYTES = 14
    CV_STRING_BUILDER = 15
    CV_STRING_CHUNK = 16

type ComptimeValue {
    kind: i32,
    type_id: i32,
    data0: i64,
    data1: i64,
    text: str,
    text_refs: *mut i64,
    extra_start: i32,
    extra_count: i32,
}
// #747: str field — owned, non-Copy now; moves/clones spell intent.

fn comptime_text_refs(value: &str) -> *mut i64:
    if value.len() == 0:
        return 0 as *mut i64
    let refs = with_alloc(8) as *mut i64
    unsafe { *refs = 1 }
    refs

impl Drop for ComptimeValue:
    move fn drop():
        if self.text_refs as i64 != 0:
            let next = unsafe { *self.text_refs } - 1
            unsafe { *self.text_refs = next }
            if next == 0:
                with_free(self.text_refs as *mut u8)
            else:
                // Another ComptimeValue still owns this immutable text. Blank
                // this header before automatic field cleanup so only the last
                // shared value releases the allocation.
                unsafe:
                    *(&raw mut self.text as *mut i64) = 0
                    *((&raw mut self.text as *mut i64) + 1) = 0

fn comptime_value_invalid() -> ComptimeValue:
    ComptimeValue {
        kind: ComptimeValueKind.CV_INVALID,
        type_id: 0,
        data0: 0,
        data1: 0,
        text: "",
        text_refs: 0 as *mut i64,
        extra_start: 0,
        extra_count: 0,
    }

fn comptime_value_void(type_id: i32) -> ComptimeValue:
    ComptimeValue {
        kind: ComptimeValueKind.CV_VOID,
        type_id,
        data0: 0,
        data1: 0,
        text: "",
        text_refs: 0 as *mut i64,
        extra_start: 0,
        extra_count: 0,
    }

fn comptime_value_int(type_id: i32, value: i64) -> ComptimeValue:
    ComptimeValue {
        kind: ComptimeValueKind.CV_INT,
        type_id,
        data0: value,
        data1: 0,
        text: "",
        text_refs: 0 as *mut i64,
        extra_start: 0,
        extra_count: 0,
    }

fn comptime_value_bool(value: i32) -> ComptimeValue:
    ComptimeValue {
        kind: ComptimeValueKind.CV_BOOL,
        type_id: 0,
        data0: value as i64,
        data1: 0,
        text: "",
        text_refs: 0 as *mut i64,
        extra_start: 0,
        extra_count: 0,
    }

fn comptime_value_str(value: &str) -> ComptimeValue:
    ComptimeValue {
        kind: ComptimeValueKind.CV_STR,
        type_id: 0,
        data0: 0,
        data1: 0,
        text: with_str_clone_ref(value),
        text_refs: comptime_text_refs(value),
        extra_start: 0,
        extra_count: 0,
    }

fn comptime_value_array(type_id: i32, extra_start: i32, extra_count: i32) -> ComptimeValue:
    ComptimeValue {
        kind: ComptimeValueKind.CV_ARRAY,
        type_id,
        data0: 0,
        data1: 0,
        text: "",
        text_refs: 0 as *mut i64,
        extra_start,
        extra_count,
    }

fn comptime_value_tuple(type_id: i32, extra_start: i32, extra_count: i32) -> ComptimeValue:
    ComptimeValue {
        kind: ComptimeValueKind.CV_TUPLE,
        type_id,
        data0: 0,
        data1: 0,
        text: "",
        text_refs: 0 as *mut i64,
        extra_start,
        extra_count,
    }

fn comptime_value_range(type_id: i32, start_value: i64, end_value: i64, inclusive: i32) -> ComptimeValue:
    ComptimeValue {
        kind: ComptimeValueKind.CV_RANGE,
        type_id,
        data0: start_value,
        data1: end_value,
        text: "",
        text_refs: 0 as *mut i64,
        extra_start: inclusive,
        extra_count: 0,
    }

fn comptime_value_struct(type_id: i32, extra_start: i32, extra_count: i32) -> ComptimeValue:
    ComptimeValue {
        kind: ComptimeValueKind.CV_STRUCT,
        type_id,
        data0: 0,
        data1: 0,
        text: "",
        text_refs: 0 as *mut i64,
        extra_start,
        extra_count,
    }

fn comptime_value_vec(type_id: i32, extra_start: i32, extra_count: i32) -> ComptimeValue:
    ComptimeValue {
        kind: ComptimeValueKind.CV_VEC,
        type_id,
        data0: 0,
        data1: 0,
        text: "",
        text_refs: 0 as *mut i64,
        extra_start,
        extra_count,
    }

fn comptime_value_map(type_id: i32, extra_start: i32, extra_count: i32) -> ComptimeValue:
    ComptimeValue {
        kind: ComptimeValueKind.CV_MAP,
        type_id,
        data0: 0,
        data1: 0,
        text: "",
        text_refs: 0 as *mut i64,
        extra_start,
        extra_count,
    }

fn comptime_value_capability(type_id: i32, capability_kind: i32, handle_id: i32, generation: i32) -> ComptimeValue:
    ComptimeValue {
        kind: ComptimeValueKind.CV_CAPABILITY,
        type_id,
        data0: capability_kind as i64,
        data1: handle_id as i64,
        text: "",
        text_refs: 0 as *mut i64,
        extra_start: generation,
        extra_count: 0,
    }

fn comptime_value_fn(type_id: i32, fn_sym: i32) -> ComptimeValue:
    ComptimeValue {
        kind: ComptimeValueKind.CV_FN,
        type_id,
        data0: fn_sym as i64,
        data1: 0,
        text: "",
        text_refs: 0 as *mut i64,
        extra_start: 0,
        extra_count: 0,
    }

fn comptime_value_enum(type_id: i32, variant_sym: i32, extra_start: i32, extra_count: i32) -> ComptimeValue:
    ComptimeValue {
        kind: ComptimeValueKind.CV_ENUM,
        type_id,
        data0: variant_sym as i64,
        data1: 0,
        text: "",
        text_refs: 0 as *mut i64,
        extra_start,
        extra_count,
    }

fn comptime_value_bytes(type_id: i32, data: &str) -> ComptimeValue:
    ComptimeValue {
        kind: ComptimeValueKind.CV_BYTES,
        type_id,
        data0: 0,
        data1: 0,
        text: with_str_clone_ref(data),
        text_refs: comptime_text_refs(data),
        extra_start: 0,
        extra_count: 0,
    }

fn comptime_value_string_builder(type_id: i32, head: i32, chunk_count: i32, byte_count: i64) -> ComptimeValue:
    ComptimeValue {
        kind: ComptimeValueKind.CV_STRING_BUILDER,
        type_id,
        data0: byte_count,
        data1: 0,
        text: "",
        text_refs: 0 as *mut i64,
        extra_start: head,
        extra_count: chunk_count,
    }

fn comptime_value_string_chunk(prev: i32, data: &str) -> ComptimeValue:
    ComptimeValue {
        kind: ComptimeValueKind.CV_STRING_CHUNK,
        type_id: 0,
        data0: prev as i64,
        data1: 0,
        text: with_str_clone_ref(data),
        text_refs: comptime_text_refs(data),
        extra_start: 0,
        extra_count: 0,
    }

fn comptime_value_is_valid(value: &ComptimeValue) -> i32:
    if value.kind == ComptimeValueKind.CV_INVALID:
        return 0
    1

fn comptime_value_is_intlike(value: &ComptimeValue) -> i32:
    if value.kind == ComptimeValueKind.CV_INT or value.kind == ComptimeValueKind.CV_BOOL:
        return 1
    0

fn comptime_value_intlike(value: &ComptimeValue) -> i64:
    value.data0

fn comptime_value_truthy(value: &ComptimeValue) -> i32:
    if value.kind == ComptimeValueKind.CV_BOOL or value.kind == ComptimeValueKind.CV_INT:
        if value.data0 != 0:
            return 1
        return 0
    -1

fn comptime_value_kind_name(kind: i32) -> str:
    if kind == ComptimeValueKind.CV_VOID: return "void"
    if kind == ComptimeValueKind.CV_INT: return "int"
    if kind == ComptimeValueKind.CV_BOOL: return "bool"
    if kind == ComptimeValueKind.CV_STR: return "str"
    if kind == ComptimeValueKind.CV_ARRAY: return "array"
    if kind == ComptimeValueKind.CV_TUPLE: return "tuple"
    if kind == ComptimeValueKind.CV_RANGE: return "range"
    if kind == ComptimeValueKind.CV_STRUCT: return "struct"
    if kind == ComptimeValueKind.CV_VEC: return "vec"
    if kind == ComptimeValueKind.CV_MAP: return "map"
    if kind == ComptimeValueKind.CV_CAPABILITY: return "capability"
    if kind == ComptimeValueKind.CV_FN: return "function"
    if kind == ComptimeValueKind.CV_ENUM: return "enum"
    if kind == ComptimeValueKind.CV_BYTES: return "bytes"
    if kind == ComptimeValueKind.CV_STRING_BUILDER: return "StringBuilder"
    if kind == ComptimeValueKind.CV_STRING_CHUNK: return "string chunk"
    "invalid"

fn comptime_value_format(value: &ComptimeValue, extras: &Vec[ComptimeValue], sema: &Sema) -> str:
    if value.kind == ComptimeValueKind.CV_VOID:
        return "void"
    if value.kind == ComptimeValueKind.CV_INT:
        return f"{value.data0}"
    if value.kind == ComptimeValueKind.CV_BOOL:
        if value.data0 != 0:
            return "true"
        return "false"
    if value.kind == ComptimeValueKind.CV_STR:
        return "\"" ++ value.text ++ "\""
    if value.kind == ComptimeValueKind.CV_RANGE:
        let dots = if value.extra_start != 0: "..=" else: ".."
        return f"{value.data0}" ++ dots ++ f"{value.data1}"
    if value.kind == ComptimeValueKind.CV_ARRAY or value.kind == ComptimeValueKind.CV_TUPLE:
        let open = if value.kind == ComptimeValueKind.CV_ARRAY: "[" else: "("
        let close = if value.kind == ComptimeValueKind.CV_ARRAY: "]" else: ")"
        var out = open
        for i in 0..value.extra_count:
            if i > 0:
                out = out ++ ", "
            out = out ++ comptime_value_format(extras.get((value.extra_start + i) as i64), extras, sema)
        return out ++ close
    if value.kind == ComptimeValueKind.CV_STRUCT:
        let resolved = sema.resolve_alias(value.type_id)
        if sema.get_type_kind(resolved) == TypeKind.TY_STRUCT:
            let te_start = sema.get_type_d1(resolved)
            let field_count = sema.get_type_d2(resolved)
            var out = sema.type_name(value.type_id) ++ " { "
            for fi in 0..field_count:
                if fi > 0:
                    out = out ++ ", "
                let field_sym = sema.type_extra.get((te_start + fi * 3) as i64)
                let field_value = extras.get((value.extra_start + fi) as i64)
                out = out ++ sema.pool_resolve(field_sym) ++ ": " ++ comptime_value_format(field_value, extras, sema)
            return out ++ " }"
    if value.kind == ComptimeValueKind.CV_VEC:
        var out = sema.type_name(value.type_id) ++ "(["
        for i in 0..value.extra_count:
            if i > 0:
                out = out ++ ", "
            out = out ++ comptime_value_format(extras.get((value.extra_start + i) as i64), extras, sema)
        return out ++ "])"
    if value.kind == ComptimeValueKind.CV_MAP:
        var out = sema.type_name(value.type_id) ++ " { "
        for i in 0..value.extra_count:
            if i > 0:
                out = out ++ ", "
            let base = value.extra_start + i * 2
            let key = extras.get(base as i64)
            let item = extras.get((base + 1) as i64)
            out = out ++ comptime_value_format(key, extras, sema) ++ ": " ++ comptime_value_format(item, extras, sema)
        return out ++ " }"
    if value.kind == ComptimeValueKind.CV_CAPABILITY:
        return "<capability " ++ capability_registry_kind_name(value.data0 as i32) ++ ">"
    if value.kind == ComptimeValueKind.CV_FN:
        return "<fn " ++ sema.pool_resolve(value.data0 as i32) ++ ">"
    if value.kind == ComptimeValueKind.CV_ENUM:
        var out: str = with_str_clone_ref(sema.pool_resolve(value.data0 as i32))
        if value.extra_count > 0:
            out = out ++ "("
            for i in 0..value.extra_count:
                if i > 0:
                    out = out ++ ", "
                out = out ++ comptime_value_format(extras.get((value.extra_start + i) as i64), extras, sema)
            out = out ++ ")"
        return out
    if value.kind == ComptimeValueKind.CV_BYTES:
        return f"Vec[u8]({value.text.len()} bytes)"
    if value.kind == ComptimeValueKind.CV_STRING_BUILDER:
        return f"StringBuilder({value.data0} bytes)"
    if value.kind == ComptimeValueKind.CV_STRING_CHUNK:
        return "<string chunk>"
    if value.type_id != 0:
        return "<" ++ sema.type_name(value.type_id) ++ ">"
    "<invalid>"

fn comptime_values_equal(lhs: &ComptimeValue, rhs: &ComptimeValue, extras: &Vec[ComptimeValue]) -> i32:
    if lhs.kind != rhs.kind:
        return 0
    if lhs.kind == ComptimeValueKind.CV_INVALID:
        return 0
    if lhs.kind == ComptimeValueKind.CV_VOID:
        return 1
    if lhs.kind == ComptimeValueKind.CV_INT or lhs.kind == ComptimeValueKind.CV_BOOL:
        if lhs.data0 == rhs.data0:
            return 1
        return 0
    if lhs.kind == ComptimeValueKind.CV_STR:
        return with_str_eq_ref(with_str_clone_ref(lhs.text), with_str_clone_ref(rhs.text))
    if lhs.kind == ComptimeValueKind.CV_RANGE:
        if lhs.data0 == rhs.data0 and lhs.data1 == rhs.data1 and lhs.extra_start == rhs.extra_start:
            return 1
        return 0
    if lhs.kind == ComptimeValueKind.CV_ARRAY or lhs.kind == ComptimeValueKind.CV_TUPLE:
        if lhs.extra_count != rhs.extra_count:
            return 0
        for i in 0..lhs.extra_count:
            let left = extras.get((lhs.extra_start + i) as i64)
            let right = extras.get((rhs.extra_start + i) as i64)
            if comptime_values_equal(left, right, extras) == 0:
                return 0
        return 1
    if lhs.kind == ComptimeValueKind.CV_STRUCT:
        if lhs.type_id != rhs.type_id or lhs.extra_count != rhs.extra_count:
            return 0
        for i in 0..lhs.extra_count:
            let left = extras.get((lhs.extra_start + i) as i64)
            let right = extras.get((rhs.extra_start + i) as i64)
            if comptime_values_equal(left, right, extras) == 0:
                return 0
        return 1
    if lhs.kind == ComptimeValueKind.CV_VEC:
        if lhs.type_id != rhs.type_id or lhs.extra_count != rhs.extra_count:
            return 0
        for i in 0..lhs.extra_count:
            let left = extras.get((lhs.extra_start + i) as i64)
            let right = extras.get((rhs.extra_start + i) as i64)
            if comptime_values_equal(left, right, extras) == 0:
                return 0
        return 1
    if lhs.kind == ComptimeValueKind.CV_MAP:
        if lhs.type_id != rhs.type_id or lhs.extra_count != rhs.extra_count:
            return 0
        for i in 0..lhs.extra_count:
            let base = i * 2
            let left_key = extras.get((lhs.extra_start + base) as i64)
            let right_key = extras.get((rhs.extra_start + base) as i64)
            if comptime_values_equal(left_key, right_key, extras) == 0:
                return 0
            let left_value = extras.get((lhs.extra_start + base + 1) as i64)
            let right_value = extras.get((rhs.extra_start + base + 1) as i64)
            if comptime_values_equal(left_value, right_value, extras) == 0:
                return 0
        return 1
    if lhs.kind == ComptimeValueKind.CV_CAPABILITY:
        if lhs.type_id == rhs.type_id and lhs.data0 == rhs.data0 and lhs.data1 == rhs.data1 and lhs.extra_start == rhs.extra_start:
            return 1
        return 0
    if lhs.kind == ComptimeValueKind.CV_FN:
        if lhs.type_id == rhs.type_id and lhs.data0 == rhs.data0:
            return 1
        return 0
    if lhs.kind == ComptimeValueKind.CV_ENUM:
        if lhs.type_id != rhs.type_id or lhs.data0 != rhs.data0 or lhs.extra_count != rhs.extra_count:
            return 0
        for i in 0..lhs.extra_count:
            let left = extras.get((lhs.extra_start + i) as i64)
            let right = extras.get((rhs.extra_start + i) as i64)
            if comptime_values_equal(left, right, extras) == 0:
                return 0
        return 1
    if lhs.kind == ComptimeValueKind.CV_BYTES:
        return with_str_eq_ref(with_str_clone_ref(lhs.text), with_str_clone_ref(rhs.text))
    if lhs.kind == ComptimeValueKind.CV_STRING_BUILDER:
        if lhs.type_id == rhs.type_id and lhs.extra_start == rhs.extra_start and lhs.extra_count == rhs.extra_count and lhs.data0 == rhs.data0:
            return 1
        return 0
    if lhs.kind == ComptimeValueKind.CV_STRING_CHUNK:
        if lhs.data0 == rhs.data0:
            return with_str_eq_ref(with_str_clone_ref(lhs.text), with_str_clone_ref(rhs.text))
        return 0
    0

// #747: explicit owned copy — ComptimeValue's text is an owned str now.
pub fn comptime_value_clone(v: &ComptimeValue) -> ComptimeValue:
    ComptimeValue { kind: v.kind, type_id: v.type_id, data0: v.data0, data1: v.data1, text: with_str_clone_ref(v.text), text_refs: comptime_text_refs(v.text), extra_start: v.extra_start, extra_count: v.extra_count }

// Read-path share: the evaluator reads a parameter on every loop iteration.
// Deep-cloning a large immutable string there is quadratic (the build.w source
// hash loop allocated 64 GiB in seconds). A tiny single-threaded refcount keeps
// the familiar value-shaped evaluator API while making either destruction
// order safe; retained semantic values still use comptime_value_clone above.
pub fn comptime_value_share(v: &ComptimeValue) -> ComptimeValue:
    if v.text_refs as i64 != 0:
        unsafe { *v.text_refs = *v.text_refs + 1 }
    let text_ptr = &raw const v.text as *const str
    ComptimeValue { kind: v.kind, type_id: v.type_id, data0: v.data0, data1: v.data1, text: unsafe *text_ptr, text_refs: v.text_refs, extra_start: v.extra_start, extra_count: v.extra_count }
