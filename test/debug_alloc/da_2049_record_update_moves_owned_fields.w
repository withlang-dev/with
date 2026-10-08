//! expect-debug-alloc: leak count=0
//! expect-stdout: A2 b 5
//! expect-stdout: x z 1
// #2049: `{ p with a: v }` consumes a base this frame owns: the new value
// moves into the result, the replaced field is dropped, the rest move over.
// The new value's statement temporary was dropped after it moved into the
// result (DOUBLE FREE), and the base was left Init with its drop retired.
type P { a: str, b: str, n: i32 }

fn set(p: P, slot: i32) -> P:
    if slot == 0: return { p with a: "A2" }
    if slot == 1: return { p with n: p.n + 4 }
    p

fn main:
    let p = P { a: "a", b: "b", n: 1 }
    let q = set(p, 0)
    let r = set(q, 1)
    let s = set(r, 2)
    print(f"{s.a} {s.b} {s.n}")
    var t = P { a: "x", b: "y", n: 1 }
    t = { t with b: "z" }
    print(f"{t.a} {t.b} {t.n}")
