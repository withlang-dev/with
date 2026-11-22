//! expect-stdout: 3 -1 1
// A distinct type is its inner type in C; `.value` is the same object, not a
// member (std.traits' TotalF64 reads it in every program the C backend
// emits).
use std.traits.TotalF64

type Meters = distinct i32

fn twice(m: Meters): m.value * 2

let a = TotalF64(1.5)
let b = TotalF64(-0.0)
print(f"{twice(Meters(1)) + 1} {b.cmp(&a)} {a.cmp(&b)}")
