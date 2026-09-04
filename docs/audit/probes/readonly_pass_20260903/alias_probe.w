use std.builtins.print_i32
type Meters = i32
type Seconds = i32
fn speed(d: Meters, t: Seconds) -> i32: d / t
fn main:
    let m: Meters = 100
    let s: Seconds = 4
    print_i32(speed(s, m))
