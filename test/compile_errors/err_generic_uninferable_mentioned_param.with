//! expect-error: cannot infer type parameter 'T' for this call

// #738: a mentioned-but-unbound type parameter means inference failed —
// the diagnostic names the inference failure instead of silently
// substituting i32 and reporting a mismatch against a type the user
// never wrote (the old output claimed "expects Wrap[i32]").

use std.builtins.int_to_string
type Wrap[T] { item: T }

fn unwrap_it[T](w: Wrap[T]) -> i64: 0

fn main:
    print(int_to_string(unwrap_it(3)))
