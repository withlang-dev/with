use Sema

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
    0 - 1

fn comptime_value_kind_name(kind: i32) -> str:
    if kind == ComptimeValueKind.CV_VOID: return "void"
    if kind == ComptimeValueKind.CV_INT: return "int"
    if kind == ComptimeValueKind.CV_BOOL: return "bool"
    if kind == ComptimeValueKind.CV_STR: return "str"
    if kind == ComptimeValueKind.CV_ARRAY: return "array"
    if kind == ComptimeValueKind.CV_TUPLE: return "tuple"
    if kind == ComptimeValueKind.CV_RANGE: return "range"
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
    0
