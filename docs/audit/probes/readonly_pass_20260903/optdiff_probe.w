use std.builtins.print_i32
use std.collections.HashMap
fn fib(n: i32) -> i32:
    if n <= 1: n else: fib(n - 1) + fib(n - 2)
fn main:
    var v: Vec[str] = Vec.new()
    v.push("a")
    v.push("bb")
    v.push("ccc")
    var total = 0
    for s in v:
        total = total + s.len() as i32
    print_i32(total)
    print_i32(fib(20))
    var m: HashMap[str, i32] = HashMap.new()
    m.insert("x", 7)
    print_i32(*m.get("x").unwrap() + total)
