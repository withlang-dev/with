//! expect-error: use of moved value
// #1710 (§10.3, D74 interim): `o?.a` takes the non-Copy field `a` out of
// the named base `o` by moving the whole Option into a temporary. Sema now
// records that move, so the second chain is "use of moved value" instead of
// a silent `Some()`. D22 stage 4 retypes a named-base chain as a view.

type P { a: str, b: i32 }

fn main:
    let o: Option[P] = Some(P { a: "xyz".clone(), b: 4 })
    print(f"{o?.a}")
    print(f"{o?.a}")
