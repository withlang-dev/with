// std.result — Result wrappers over built-in combinators.

pub fn is_ok[T, E](r: Result[T, E]) -> bool =
    r.is_ok()

pub fn is_err[T, E](r: Result[T, E]) -> bool =
    r.is_err()

pub fn unwrap_or[T, E](r: Result[T, E], fallback: T) -> T =
    r.unwrap_or(fallback)
