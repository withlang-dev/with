//! expect-stdout: 14 3
// #2220: a map built in a function called under comptime iterates as
// `for (k, v) in m` (D44): the evaluator binds the for pattern and walks
// the map's entries as (key, value) tuples.
use std.collections.HashMap

fn tally(n: i32) -> i32:
    var m: HashMap[i32, i32] = HashMap.new()
    for i in 0..n: m.insert(i, i * i)
    var s = 0
    for (k, v) in m: s = s + v
    s

fn pairs() -> i32:
    var v: List[(i32, i32)] = List.new()
    v.push((1, 2))
    var s = 0
    for (a, b) in v: s = s + a + b
    s

let t = comptime tally(4)
let p = comptime pairs()
print(f"{t} {p}")
