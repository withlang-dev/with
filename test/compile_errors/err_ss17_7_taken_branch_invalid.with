//! expect-check-fail: unknown method 'missing_method_xyz'

fn only_taken_is_checked[T](val: T) -> i32:
    comptime if T.is_copy():
        val.missing_method_xyz()
    else:
        0

fn main:
    only_taken_is_checked(5)
