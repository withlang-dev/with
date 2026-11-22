//! expect-stdout: 8
//! expect-stdout: 8
//! expect-stdout: b
//! expect-stdout: none

// #2524 (D22, D27): `??` looks through a view of an Option. `v[0]` names the
// element place, a `&Option[i32]`; its default is the payload, an i32, and
// MIR reads the carrier through the view. The `&Option` was matched as a
// carrier itself and refused, then lowered as the Option it is not.
fn main:
    let v: List[Option[i32]] = [Some(8)]
    print(f"{v[0] ?? 0}")
    let e = v[0]
    print(f"{e ?? 0}")
    let names: List[Option[str]] = [Some("b"), None]
    print(names[0] ?? "none")
    print(names[1] ?? "none")
