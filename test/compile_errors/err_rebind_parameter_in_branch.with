//! expect-check-fail: shadowing is not allowed for 'x'

// D220 (§29.8): as err_rebind_copy_in_branch, for a parameter.
fn f(x: i32, c: bool) -> i32:
    if c:
        var x = x
        print(x)
    x

fn main: print(f(1, true))
