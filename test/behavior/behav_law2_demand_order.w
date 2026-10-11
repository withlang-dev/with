//! expect-stdout: T is 4 bytes
//! expect-stdout: 3
//! expect-stdout: T is 4 bytes
//! expect-stdout: 4

// Law 2 (mission.md): a demand first binds the unknowns the expression's
// own signature leaves open, then conversions apply between two known
// types — and an expression's own operands bind before the outer demand
// fills what remains. `let x: Option[i32] = ident(3)` is therefore
// `Some(ident(3))` with `T := i32` (4 bytes), never `ident(Some(3))` with
// `T := Option[i32]`: `ident` reports the size of the `T` it was
// instantiated at. `make()` binds its `T` from the demand (phase one,
// #2212); `first(3)` against `Option[T]` is refused (err_d103_no_inference).
fn ident[T](t: T) -> T:
    print(f"T is {sizeof[T]()} bytes")
    t
fn make[T]() -> Option[T]: None

fn main:
    let x: Option[i32] = ident(3)
    print(x.unwrap())
    let y: Option[i32] = make()
    let z: Option[i32] = ident(4)
    print(y.unwrap_or(0) + z.unwrap())
