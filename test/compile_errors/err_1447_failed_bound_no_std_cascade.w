//! expect-error: does not implement trait 'Display' required by bound 'T: Display'
//! expect-check-fail-not: std/builtins.w
// #1447: a failed bound is the whole diagnostic. The generic body used to be
// checked under the failed instantiation, which reported
// "unknown method 'to_str'" inside the embedded std/builtins.w.

type Opaque { n: i32 }

fn main:
    let o = Opaque { n: 1 }
    print(o)
