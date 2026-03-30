//! expect-check-fail: comptime can only call comptime functions

comptime fn noisy() -> i32:
    print("hi")
    0
