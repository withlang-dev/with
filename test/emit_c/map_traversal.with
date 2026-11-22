//! expect-stdout: 6 6
//! expect-stdout: 60 3

// #1434: `for (k, v) in map` (D44: traversal observes — the loop binds `&K`
// and `&V` of each occupied slot) through the C backend, which refused it.
use std.collections.HashMap

fn main:
    var m: HashMap[i32, str] = HashMap.new()
    m.insert(1, "a")
    m.insert(2, "bb")
    m.insert(3, "ccc")
    var keys = 0
    var lens = 0
    for (k, v) in m:
        keys += k
        lens += v.len() as i32
    print(f"{keys} {lens}")
    var scores: HashMap[str, i32] = HashMap.new()
    scores.insert("x", 10)
    scores.insert("yy", 20)
    scores.insert("z", 30)
    var sum = 0
    var names = 0
    for (name, score) in scores:
        sum += score
        names += 1
    print(f"{sum} {names}")
