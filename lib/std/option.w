// std.option — Option wrappers over built-in combinators.
//
// Note: wrappers are currently concrete for i32 payloads due generic
// signature limitations in the current Sema path.

pub fn is_some(opt: ?i32) -> bool:
    opt.is_some()

pub fn is_none(opt: ?i32) -> bool:
    opt.is_none()

pub fn unwrap_or(opt: ?i32, fallback: i32) -> i32:
    opt.unwrap_or(fallback)

pub fn map(opt: ?i32, f: fn(i32) -> i32) -> ?i32:
    opt.map(f)

pub fn and_then(opt: ?i32, f: fn(i32) -> ?i32) -> ?i32:
    opt.and_then(f)

pub fn or_else(opt: ?i32, f: fn() -> ?i32) -> ?i32:
    opt.or_else(f)

pub fn filter(opt: ?i32, pred: fn(i32) -> bool) -> ?i32:
    opt.filter(pred)

pub fn zip(a: ?i32, b: ?i32) -> ?(i32, i32):
    a.zip(b)

pub fn cloned(opt: ?i32) -> ?i32:
    opt.cloned()

pub fn transpose(opt: ?Result[i32, str]) -> Result[?i32, str]:
    opt.transpose()
