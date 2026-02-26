// Test: std.collections import and wrappers
use std.collections

fn plus_one(x: i32) -> i32:
    x + 1

fn main -> i32:
    var counts: HashMap[str, i32] = HashMap.new()
    increment(counts, "a")
    increment(counts, "a")
    assert(counts.get("a").unwrap() == 2)

    update(counts, "a", 0, plus_one)
    assert(counts.get("a").unwrap() == 3)

    var grouped: HashMap[str, Vec[i32]] = HashMap.new()
    append(grouped, "vals", 4)
    append(grouped, "vals", 5)
    let vals = grouped.get("vals").unwrap()
    assert(vals.len() == 2)
    assert(vals.get(0) == 4)
    assert(vals.get(1) == 5)

    decrement(counts, "a")
    assert(counts.get("a").unwrap() == 2)

