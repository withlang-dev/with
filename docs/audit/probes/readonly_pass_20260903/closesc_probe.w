use std.builtins.print_i32
fn make_adder(x: &i32) -> fn() -> i32:
    () => *x + 1
fn main:
    let f = {
        let v = 10
        make_adder(&v)
    }
    print_i32(f())
