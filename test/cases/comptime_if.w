// Test: comptime if conditional compilation
fn value -> i32:
    comptime if true: 42 else 0

fn main -> i32:
    if value() == 42 then 0 else 1
