//! expect-error: issue155 exported function

@[c_export("issue155_exported")]
fn exported() -> i32:
    comptime_error("issue155 exported function")
