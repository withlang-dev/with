//! expect-check-fail: may outlive its origin
// §5.2 (#625): same escape via explicit `return`.
type View ephemeral { p: &i32 }

fn leak() -> List[View]:
    let x = 5
    return [View { p: &x }]

fn main:
    let _ = leak()
