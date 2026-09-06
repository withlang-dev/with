// T8-9/12: one generic fn monomorphized at two concrete types
// (check_fn_body_concrete :3632). Expect check PASS and run prints 1, one.
use std.builtins.int_to_string

fn ident[T](x: T) -> T: x

fn main:
    print(int_to_string(ident(1)))
    print(ident("one"))
