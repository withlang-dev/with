//! expect-stdout: single before=none after=7
//! expect-stdout: cross before=none after=9 len=2
//! expect-stdout: field first=11 after=11
//! expect-stdout: loop sum=45

// D172 (§19.1): a `Memo` updated through a read-only view shows the new
// value when read after the update, in the same function and across a
// call. The optimizer may assume nothing inside the marker is unchanged.

use std.memo

type Table {
    cache: Memo[i32, i64],
    hits: i32,
}

fn fill(m: &Memo[i32, i64], key: i32, value: i64):
    m.insert(key, value)

fn show(v: Option[i64]) -> str:
    match v:
        Some(x) => f"{x}"
        None => "none"

fn lookup(t: &Table, key: i32) -> i64:
    match t.cache.get(key):
        Some(v) => v
        None =>
            t.cache.insert(key, key + 10)
            key + 10

fn main:
    let single: Memo[i32, i64] = Memo.new()
    let before = single.get(1)
    single.insert(1, 7)
    print(f"single before={show(before)} after={show(single.get(1))}")

    let cross: Memo[i32, i64] = Memo.new()
    let cross_before = cross.get(2)
    fill(cross, 2, 9)
    fill(cross, 3, 4)
    print(f"cross before={show(cross_before)} after={show(cross.get(2))} len={cross.len()}")

    let t = Table { cache: Memo.new(), hits: 0 }
    let first = lookup(t, 1)
    print(f"field first={first} after={show(t.cache.get(1))}")

    let squares: Memo[i32, i64] = Memo.new()
    var sum: i64 = 0
    for i in 0..10:
        fill(squares, i, i)
        sum += squares.get(i).unwrap()
    print(f"loop sum={sum}")
