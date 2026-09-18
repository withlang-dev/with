use std.builtins.print
use std.builtins.print_i32
use std.builtins.print_i64
use std.builtins.print_bool
use std.builtins.assert
use std.builtins.assert_eq
use std.builtins.assert_ne
use std.builtins.require
use std.builtins.check

fn main:
    print("hello-builtins")
    print_i32(-42)
    print_i64(1234567890123i64)
    print_bool(true)
    assert(true, "pass")
    require(true, "pass")
    check(true, "pass")
    assert_eq(1, 1)
    assert_ne(1, 2)
    let s1 = (42).to_string()
    let s2 = (true).to_string()
    print(s1)
    print(s2)
    print(int_to_string(99i64))
    let u: u32 = 7u32
    print(u.to_string())
