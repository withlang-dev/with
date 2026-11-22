//! expect-check-fail: mutable global access is not allowed in comptime

var GLOBAL_COUNT: i32 = 0

comptime fn read_global() -> i32:
    GLOBAL_COUNT
