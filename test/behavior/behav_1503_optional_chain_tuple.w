//! expect-stdout: 4
//! expect-stdout: 0
//! expect-stdout: Some(4)
//! expect-stdout: Some(xyz)
//! expect-stdout: 7

// #1503 (§10.3): a tuple element is a field, so `o?.1` is `Option[i32]`;
// Sema typed it as the receiver and the f-string form failed MIR lowering.
// (Each chain reads a fresh binding: a second chain on the same Option
// reads a reset value, filed separately.)

fn first(o: Option[(str, i32)]) -> Option[i32]: o?.1

fn main:
    let o: Option[(str, i32)] = Some(("xyz".clone(), 4))
    print(f"{first(o) ?? 0}")
    let n: Option[(str, i32)] = None
    print(f"{first(n) ?? 0}")
    let p: Option[(str, i32)] = Some(("xyz".clone(), 4))
    print(f"{p?.1}")
    let s: Option[(str, i32)] = Some(("xyz".clone(), 4))
    print(f"{s?.0}")
    let q: Option[(i32, i32)] = Some((3, 7))
    print(f"{q?.1 ?? 0}")
