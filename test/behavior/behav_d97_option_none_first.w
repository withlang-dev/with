//! expect-stdout: true false true
//! expect-stdout: some 3
//! expect-stdout: none
// D97: Option is declared `None | Some(T)`, and derived Ord orders variants
// by declaration, so nothing sorts before any value. The reorder changes no
// behavior beyond the order: matching, is_some/is_none and unwrap still see
// the same variants.
let a: Option[i32] = None
let b = Some(1)
let c = Some(2)
print(f"{a < b} {c < b} {b < c}")

fn show(o: Option[i32]):
    match o:
        Some(n) => print(f"some {n}")
        None => print("none")

show(Some(3))
if Some(3).is_some() and a.is_none(): show(None)
