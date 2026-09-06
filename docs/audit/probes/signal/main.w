use std.signal
use std.builtins.print_i32
fn main -> i32:
    print_i32(sigint())
    print_i32(sigterm())
    print_i32(sigkill())
    print_i32(raise_signal(0))
    0
