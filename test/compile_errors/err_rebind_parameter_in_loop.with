//! expect-check-fail: shadowing is not allowed for 'x'

// D220 (§29.8): as err_rebind_copy_in_loop, for a parameter.
fn f(x: i32) -> i32:
    for i in 0..3:
        var x = x
        print(x)
    x

fn main: print(f(1))
