// std.result — Result wrappers over built-in combinators.
//
// Note: wrappers are currently concrete due generic signature limitations
// in the current Sema path.

pub fn is_ok(r: Result[i32, i32]) -> bool =
    r.is_ok()

pub fn is_err(r: Result[i32, i32]) -> bool =
    r.is_err()

pub fn unwrap_or(r: Result[i32, i32], fallback: i32) -> i32 =
    r.unwrap_or(fallback)

pub fn map(r: Result[i32, i32], f: fn(i32) -> i32) -> Result[i32, i32] =
    r.map(f)

pub fn map_err(r: Result[i32, i32], f: fn(i32) -> i32) -> Result[i32, i32] =
    r.map_err(f)

pub fn and_then(r: Result[i32, i32], f: fn(i32) -> Result[i32, i32]) -> Result[i32, i32] =
    r.and_then(f)

pub fn or_else(r: Result[i32, i32], f: fn(i32) -> Result[i32, i64]) -> Result[i32, i64] =
    r.or_else(f)

pub fn ok(r: Result[i32, i32]) -> ?i32 =
    r.ok()

pub fn err(r: Result[i32, i32]) -> ?i32 =
    r.err()

pub fn transpose(r: Result[?i32, str]) -> ?Result[i32, str] =
    r.transpose()

pub fn context(r: Result[i32, i32], msg: str) -> Result[i32, ContextError[i32]] =
    r.context(msg)

pub fn with_context(r: Result[i32, i32], f: fn() -> str) -> Result[i32, ContextError[i32]] =
    r.with_context(f)
