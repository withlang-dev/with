use std.thread
use std.builtins.print_i32
fn main:
    var total = 0
    let worker = () => { total = total + 1; 0 }
    let h = spawn_os(worker)
    print_i32(join(&h) + total)
