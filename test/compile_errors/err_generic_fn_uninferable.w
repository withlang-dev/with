//! expect-check-fail: cannot infer type parameter

// #598: an uninferable type param gets ONE restructure-teaching diagnostic
// (annotate the binding or pass an argument mentioning T), not a cascade of
// bare "unknown type" errors.

use std.builtins.print_i32
fn make[T]() -> List[T]:
    List.new()

fn main:
    let x = make()
    print_i32(x.len() as i32)
