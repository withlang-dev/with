//! expect-check-fail: may outlive its origin
// §5.2 (#626): an owned local coerced into a `&T` field makes the struct borrow
// it; returning that view where the origin (a dying local) doesn't outlive it
// is rejected. Previously passed check silently (caller dangled).
type View ephemeral { s: &str }
fn f(a: str, b: str) -> View:
    let owned = a ++ b
    return View { s: owned }
fn main:
    let _ = f("x", "y")
