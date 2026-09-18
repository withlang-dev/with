use std.random
use std.builtins.print_i32
fn main -> i32:
    seed(42)
    var i = 0
    while i < 5:
        print_i32(next_i32())
        i = i + 1
    print_i32(range_i32(5, 5))
    print_i32(range_i32(10, 5))
    print_i32(if chance(0): 1 else: 0)
    print_i32(if chance(100): 1 else: 0)
    var r = 0
    seed(7)
    var j = 0
    while j < 100:
        r = range_i32(0, 10)
        if r < 0 or r >= 10:
            print_i32(-999)
        j = j + 1
    print_i32(777)
    0
