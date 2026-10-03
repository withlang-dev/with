//! expect-stdout: 7
// §5.2 (#625): a plain array is a value type (not a heap container), so an
// ephemeral element type is allowed.
type View ephemeral { p: &i32 }
fn main:
    let x = 7
    let a = [View { p: &x }]
    print_i32(*a[0].p)
