use std.builtins.print_i32
use std.builtins.print
fn main -> i32:
    print_i32(if "hello".hash_value() == -3758590733434492115: 1 else: 0)
    print_i32(if "".hash_value() == 1469598103934665603: 1 else: 0)
    print_i32("b".cmp("a"))
    print_i32("a".cmp("b"))
    print_i32("a".cmp("a"))
    print_i32("abc".cmp("abd"))
    print_i32("abc".cmp("ab"))
    print_i32(true.cmp(false))
    print_i32(false.cmp(false))
    print_i32(i32.default())
    print_i32(if bool.default(): 1 else: 0)
    var five: i32 = 5
    print_i32(five.clone())
    var seven: i32 = 7
    print(seven.debug_str())
    print(true.debug_str())
    print("hi".debug_str())
    0
