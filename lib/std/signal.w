// std.signal — minimal signal constants and helpers.

extern fn raise(sig: i32) -> i32

pub fn sigint() -> i32 =
    2

pub fn sigterm() -> i32 =
    15

pub fn sigkill() -> i32 =
    9

pub fn raise_signal(sig: i32) -> i32 =
    raise(sig)
