//! expect-stdout: 30
// §5.2 (#625, decisions.md D2): a container of an ephemeral handle whose fields
// are all OWNED (the stdlib Vec[Workspace] shape) carries no stack view-origin,
// so it is freely usable as a local and by-value parameter.
use std.builtins.print_i32
type Handle ephemeral { token: str, id: i32 }
fn batch(hs: Vec[Handle]) -> i32:
    var total = 0
    for h in hs:
        total = total + h.id
    total
fn main:
    var hs = Vec.new()
    hs.push(Handle { token: "a", id: 10 })
    hs.push(Handle { token: "b", id: 20 })
    print_i32(batch(hs))
