use std.collections
use std.iter

fn via_local(s: str) -> i32:
    let n = s.len
    n

fn direct_ret(s: str) -> i32:
    s.len

fn plus_one(s: str) -> i32:
    s.len + 1

fn main():
    var a: Vec[str] = Vec.new()
    a.push("a")
    a.push("abc")
    let r1 = map(a, via_local)
    print(f"via_local: [0]={r1[0]} [1]={r1[1]}\n")
    var b: Vec[str] = Vec.new()
    b.push("a")
    b.push("abc")
    let r2 = map(b, direct_ret)
    print(f"direct_ret: [0]={r2[0]} [1]={r2[1]}\n")
    var c: Vec[str] = Vec.new()
    c.push("a")
    c.push("abc")
    let r3 = map(c, plus_one)
    print(f"plus_one: [0]={r3[0]} [1]={r3[1]}\n")
