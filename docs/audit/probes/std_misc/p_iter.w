use std.collections
use std.iter

fn is_even(x: i32) -> bool:
    x % 2 == 0

fn str_len_as_i32(s: str) -> i32:
    s.len

fn expect(label: str, ok: bool):
    if ok:
        print(f"PASS: {label}\n")
    else:
        print(f"FAIL: {label}\n")

fn five() -> Vec[i32]:
    var v: Vec[i32] = Vec.new()
    v.push(1)
    v.push(2)
    v.push(3)
    v.push(4)
    v.push(5)
    v

fn main():
    expect("sum", sum(five()) == 15)
    let a: [i32; 3] = [1, 2, 3]
    // count(a) omitted: T-inference fails (see finding F-iter-1); a.len works:
    expect("array len", a.len == 3)
    expect("contains yes", contains(a, 2) == true)
    expect("contains no", contains(a, 9) == false)
    let evens = filter(five(), is_even)
    expect("filter len", evens.len == 2)
    expect("filter sum", sum(evens) == 6)
    // empty vec edges
    var e: Vec[i32] = Vec.new()
    expect("sum empty", sum(e) == 0)
    var e2: Vec[i32] = Vec.new()
    expect("filter empty", filter(e2, is_even).len == 0)
    // map over str vec
    var sv: Vec[str] = Vec.new()
    sv.push("a")
    sv.push("abc")
    let lens = map(sv, str_len_as_i32)
    expect("map len", lens.len == 2)
    expect("map sum", sum(lens) == 4)
    // iter_sum via Vec iter
    expect("iter_sum", iter_sum(five().iter()) == 15)
    var e3: Vec[i32] = Vec.new()
    expect("iter_sum empty", iter_sum(e3.iter()) == 0)
