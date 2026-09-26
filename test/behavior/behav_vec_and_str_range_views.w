//! expect-stdout: 5
//! expect-stdout: 3
//! expect-stdout: 2
//! expect-stdout: 3

// §4.8a / D27 (#1632): a range on a Vec is a `[]T` view of it; it passes
// where `[]T` is expected and the Vec stays valid. A str's bytes slice the
// same way through as_bytes().
fn total(xs: []i32) -> i32:
    var t = 0
    for x in xs: t = t + x
    t
fn main:
    var v: Vec[i32] = Vec.new()
    v.push(2)
    v.push(3)
    print(total(v[..]))
    print(total(v[1..]))
    print(total(v[..1]))
    print("hello".as_bytes()[2..].len())
