use std.iter
use std.builtins.int_to_string

fn slen(s: str) -> i32:
    s.len() as i32

fn is_even(x: i32) -> bool:
    x == 10 or x == 30

fn mk() -> Vec[i32]:
    let v: Vec[i32] = Vec.new()
    v.push(7)
    v.push(10)
    v.push(21)
    v.push(30)
    v

fn main -> i32:
    print("sum=" ++ int_to_string(sum(mk()) as i64))
    print("count=" ++ count(mk()).to_string())
    print("contains10=" ++ contains(mk(), 10).to_string())
    print("contains99=" ++ contains(mk(), 99).to_string())
    let evens = filter(mk(), is_even)
    print("evens_len=" ++ evens.len().to_string())
    print("evens0=" ++ int_to_string(evens.get(0) as i64))
    print("evens1=" ++ int_to_string(evens.get(1) as i64))
    let it = mk().iter()
    print("iter_sum=" ++ int_to_string(iter_sum(it) as i64))
    let e1: Vec[i32] = Vec.new()
    print("sum_empty=" ++ int_to_string(sum(e1) as i64))
    let e2: Vec[i32] = Vec.new()
    let it2 = e2.iter()
    print("iter_sum_empty=" ++ int_to_string(iter_sum(it2) as i64))
    let words: Vec[str] = Vec.new()
    words.push("a")
    words.push("abcd")
    let lens = map(words, slen)
    print("map0=" ++ int_to_string(lens.get(0) as i64))
    print("map1=" ++ int_to_string(lens.get(1) as i64))
    0
