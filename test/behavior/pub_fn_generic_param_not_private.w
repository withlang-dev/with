//! expect-stdout: 7
// A `pub fn`'s own type parameter and Option/Vec of public types are not
// private types; the §18.1 signature check must stay silent here.

use std.builtins.print_i32

pub type Pair { a: i32, b: i32 }

pub fn first[T](xs: &Vec[T]) -> &T:
    xs.get(0)

pub fn total(p: &Pair, extra: Option[i32]) -> i32:
    p.a + p.b + extra.unwrap_or(0)

fn main:
    let p = Pair { a: 3, b: 4 }
    print_i32(total(&p, None))
