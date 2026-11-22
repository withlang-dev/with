//! expect-check-fail: may outlive its origin
// §5.2 (#626): same escape in tail position.
type View ephemeral { s: &str }
fn f(a: str, b: str) -> View:
    let owned = a ++ b
    View { s: owned }
fn main:
    let _ = f("x", "y")
