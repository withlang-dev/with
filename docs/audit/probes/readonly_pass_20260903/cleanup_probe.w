use std.builtins.print_i32
var log: i32 = 0
fn main:
    for i in 0..5:
        defer: log = log + 1
        errdefer: log = log + 100
        if i == 2:
            break
    print_i32(log)
    'skip:
        defer: log = log + 1000
        goto 'done
    'done:
    print_i32(log)
