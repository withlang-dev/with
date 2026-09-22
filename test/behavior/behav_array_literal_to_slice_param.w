//! expect-stdout: 5
//! expect-stdout: -1
//! expect-stdout: 5
//! expect-stdout: 3

// #1229: an array literal passed to a `[]T` parameter is the obvious spelling
// of `let xs = [...]; f(xs)`. Sema typed the literal AS the slice and MirLower
// aggregated the elements into the slice-typed temp, so the callee received
// `{ptr = 5, len = 6}` and segfaulted (or summed 0 over `[]str`). The literal
// is its `[T; N]` array, built in a statement temporary and sliced for the
// call, exactly like the named form.
fn first(values: []i32) -> i32:
    if values.len() == 0: return -1
    values[0]

fn total(xs: []str) -> i64:
    var n = 0i64
    for x in xs: n = n + x.len()
    n

fn count(xs: []Vec[i32]) -> i32:
    var n = 0
    for x in xs: n = n + x.len() as i32
    n

fn main:
    print(f"{first([5, 6])}")
    print(f"{first([])}")
    print(f"{total(["ab", "cde"])}")
    var a: Vec[i32] = Vec.new()
    a.push(1)
    var b: Vec[i32] = Vec.new()
    b.push(2)
    b.push(3)
    print(f"{count([a, b])}")
