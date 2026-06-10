//! expect-check-fail: return not allowed in defer [E0901]

fn bad_errdefer_return -> i32:
    errdefer:
        return 42
    0
