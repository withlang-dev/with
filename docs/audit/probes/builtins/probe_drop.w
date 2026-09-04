use std.builtins.drop
use std.builtins.print

fn main:
    let s = "owned-string"
    drop(s)
    print("after-drop")
