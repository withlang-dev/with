// RECORD of first iter probe attempt (fails to compile — see report).
// sum/filter/contains take Vec by value, so reusing `v` errors with
// "use of moved value". Kept verbatim as evidence for the ownership finding.
use std.iter
use std.builtins.int_to_string

fn slen(s: str) -> i32:
    s.len() as i32

fn is_even(x: i32) -> bool:
    x % 2 == 0

fn main -> i32:
    let v: Vec[i32] = Vec.new()
    v.push(10)
    v.push(20)
    v.push(30)
    print("sum=" ++ int_to_string(sum(v) as i64))
    print("contains20=" ++ contains(v, 20).to_string())
    print("contains99=" ++ contains(v, 99).to_string())
    let evens = filter(v, is_even)
    print("evens_len=" ++ evens.len().to_string())
    print("evens0=" ++ int_to_string(evens.get(0) as i64))
    print("evens1=" ++ int_to_string(evens.get(1) as i64))
    let total = iter_sum(v.iter())
    print("iter_sum=" ++ int_to_string(total as i64))
    let empty: Vec[i32] = Vec.new()
    print("sum_empty=" ++ int_to_string(sum(empty) as i64))
    print("iter_sum_empty=" ++ int_to_string(iter_sum(empty.iter()) as i64))
    let words: Vec[str] = Vec.new()
    words.push("a")
    words.push("abcd")
    let lens = map(words, slen)
    print("map0=" ++ int_to_string(lens.get(0) as i64))
    print("map1=" ++ int_to_string(lens.get(1) as i64))
    0
