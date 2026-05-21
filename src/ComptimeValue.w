use Sema
use CapabilityRegistry

extern fn with_str_eq(a: str, b: str) -> i32

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

type ComptimeValue {
    kind: i32,
    type_id: i32,
    data0: i64,
    data1: i64,
    text: str,
    extra_start: i32,
    extra_count: i32,
}

fn comptime_value_invalid() -> ComptimeValue:
    ComptimeValue {
        kind: ComptimeValueKind.CV_INVALID,
        type_id: 0,
        data0: 0,
        data1: 0,
        text: "",
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
        extra_start: 0,
        extra_count: 0,
    }

fn comptime_value_str(value: str) -> ComptimeValue:
    ComptimeValue {
        kind: ComptimeValueKind.CV_STR,
        type_id: 0,
        data0: 0,
        data1: 0,
        text: value,
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
        extra_start,
        extra_count,
    }

fn comptime_value_is_valid(value: ComptimeValue) -> i32:
    if value.kind == ComptimeValueKind.CV_INVALID:
        return 0
    1

fn comptime_value_is_intlike(value: ComptimeValue) -> i32:
    if value.kind == ComptimeValueKind.CV_INT or value.kind == ComptimeValueKind.CV_BOOL:
        return 1
    0

fn comptime_value_intlike(value: ComptimeValue) -> i64:
    value.data0

fn comptime_value_truthy(value: ComptimeValue) -> i32:
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
    "invalid"

fn comptime_value_format(value: ComptimeValue, extras: Vec[ComptimeValue], sema: Sema) -> str:
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
        var out = sema.pool_resolve(value.data0 as i32)
        if value.extra_count > 0:
            out = out ++ "("
            for i in 0..value.extra_count:
                if i > 0:
                    out = out ++ ", "
                out = out ++ comptime_value_format(extras.get((value.extra_start + i) as i64), extras, sema)
            out = out ++ ")"
        return out
    if value.type_id != 0:
        return "<" ++ sema.type_name(value.type_id) ++ ">"
    "<invalid>"

fn comptime_values_equal(lhs: ComptimeValue, rhs: ComptimeValue, extras: Vec[ComptimeValue]) -> i32:
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
        return with_str_eq(lhs.text, rhs.text)
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
    0
