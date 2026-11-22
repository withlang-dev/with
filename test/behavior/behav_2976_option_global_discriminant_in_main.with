//! expect-stdout: none
//! expect-stdout: some 2
//! expect-stdout: ok
// #2976: a module global's discriminant read in `main` (`a.is_none()`, a
// match) — the place is the global itself, with no projection, and codegen
// asked the projected-type table for it, which knows only projected places:
// "discriminant rvalue 0: place 0 has no type". The type is the local's own.
let a: Option[i32] = None
let b: Option[i32] = Some(2)
fn main:
    if a.is_none(): print("none")
    match b:
        Some(v) => print(f"some {v}")
        None => print("never")
    if b.is_some(): print("ok")
