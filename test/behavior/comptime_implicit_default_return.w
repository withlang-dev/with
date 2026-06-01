comptime fn touch():
    {}

comptime fn implicit_zero() -> i32:
    touch()

comptime fn explicit_empty_return() -> i32:
    return

const IMPLICIT_ZERO: i32 = comptime implicit_zero()
const EXPLICIT_ZERO: i32 = comptime explicit_empty_return()

fn main:
    assert(IMPLICIT_ZERO == 0)
    assert(EXPLICIT_ZERO == 0)
