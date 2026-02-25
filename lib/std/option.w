// std.option — Option wrappers over built-in combinators.

pub fn is_some[T](opt: Option[T]) -> bool =
    opt.is_some()

pub fn is_none[T](opt: Option[T]) -> bool =
    opt.is_none()

pub fn unwrap_or[T](opt: Option[T], fallback: T) -> T =
    opt.unwrap_or(fallback)

pub fn filter[T](opt: Option[T], pred: fn(T) -> bool) -> Option[T] =
    opt.filter(pred)
