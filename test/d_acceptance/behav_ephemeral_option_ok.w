//! expect-stdout: 5
// §5.2 (#625): value wrappers (Option) still propagate ephemerality and are
// allowed — only heap containers are banned.
use std.builtins.print_i32
type View ephemeral { p: &i32 }
fn main:
    let x = 5
    let o: Option[View] = .Some(View { p: &x })
    match o:
        .Some(v) => print_i32(*v.p)
        .None => print("none")
