//! expect-exit: 0

// D27 E1: `q` is `&*const i32`; the cast materializes and converts the Copy
// pointee, never the slot address.

fn main:
    let x = 5
    var v: List[*const i32] = List.new()
    let p = &raw const x
    v.push(p)
    let direct = p as i64
    let q = v[0]
    let through = q as i64
    assert(direct == through)
    let typed: *const i32 = v[0]
    assert(typed as i64 == direct)
