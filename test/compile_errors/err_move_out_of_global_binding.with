//! expect-check-fail: cannot move out of global `g`

// #1242: a global always holds a value and has no drop flag. Moving it into a
// local left the old bytes in the global: the reassignment dropped them, and
// so did the caller of the returned value (debug-alloc: DOUBLE FREE).

type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): {}
var g: List[Tok] = List.new()

fn take() -> List[Tok]:
    let out = g
    g = List.new()
    out

fn main:
    g.push(Tok { id: 1 })
    let t = take()
    print(f"{t.len()}")
