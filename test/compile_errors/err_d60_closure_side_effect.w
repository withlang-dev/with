//! expect-check-fail: closure return type mismatch

// §4.10: a tail of any type but Unit is the body's value and must match the
// declared return. A closure body that also mutates a capture is no
// exception (the removed closure_default_from_side_effect accepted this
// and lowered an Option into the i32 return slot: invalid MIR).

var xs: Vec[i32] = Vec.new()
fn main:
    xs.push(5)
    let f: fn() -> i32 = () => xs.pop()
    print(f())
