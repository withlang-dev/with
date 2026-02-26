// Test: comptime_error only fires on taken branch
fn main -> i32:
    // comptime_error should NOT fire because condition is false
    comptime if 1 == 2:
        comptime_error("this should never fire")

    // But regular comptime if with true condition works
    comptime if 1 == 1:
        let x = 42
        assert(x == 42)

