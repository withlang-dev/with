//! expect-check-fail: type `Point` is declared twice in this module

// #2066: two declarations of one type name in one module were two types.
// The name meant the later, anything resolved between them kept the
// earlier, and `with check` said ok.

type Point { x: i32 }
type Point { y: i64 }

fn main:
    print("unreachable")
