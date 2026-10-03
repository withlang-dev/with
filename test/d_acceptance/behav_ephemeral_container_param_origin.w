//! expect-stdout: 5
// §5.2 (#625): a container that borrows a PARAMETER (not a stack local) does
// not outlive its origin — Rust-legal, and allowed here.
type View ephemeral { p: &i32 }
fn collect_one(src: &i32) -> Vec[View]:
    var v = Vec.new()
    v.push(View { p: src })
    v
fn main:
    let x = 5
    let v = collect_one(&x)
    for view in v:
        print_i32(*view.p)
