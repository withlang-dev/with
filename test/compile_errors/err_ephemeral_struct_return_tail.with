//! expect-check-fail: may outlive its origin
// §5.1/§5.2 (#625, decisions.md D2): a bare ephemeral value returned in tail
// position is escape-checked in-scope (this path previously leaked silently).
type View ephemeral { p: &i32 }

fn leak() -> View:
    let x = 5
    View { p: &x }

fn main:
    let _ = leak()
