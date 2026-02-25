// Test: References and dereferencing
fn inc(ptr: &mut i32) -> void =
    *ptr = *ptr + 1

fn main() -> i32 =
    var x = 41
    inc(&mut x)
    if x == 42 then 0 else 1
