//! expect-stdout: 20
// §5.1 (#625): the sanctioned idiom — store indices into the owning collection
// rather than ephemeral borrows.
use std.builtins.print_i32
fn main:
    var v: List[i32] = List.new()
    v.push(10)
    v.push(20)
    let idx = 1
    print_i32(v[idx as i64])
