//! expect-stdout: ok
// D22 acceptance cell, promoted 2026-10-18. D22 owned-demand materialization of Option[&V].unwrap()
// must deref exactly once in every return spelling.

use std.collections.HashMap
fn tail_chain(m: &HashMap[i32, i32], k: i32) -> i32:
    m.get(k).unwrap()

fn explicit_return(m: &HashMap[i32, i32], k: i32) -> i32:
    return m.get(k).unwrap()

fn bound_tail(m: &HashMap[i32, i32], k: i32) -> i32:
    let o = m.get(k)
    o.unwrap()

fn bound_local_then_return(m: &HashMap[i32, i32], k: i32) -> i32:
    let v = m.get(k).unwrap()
    return v

fn tail_with_cast(m: &HashMap[i32, i32], k: i32) -> i64:
    m.get(k).unwrap() as i64

fn main:
    var m: HashMap[i32, i32] = HashMap.new()
    m.insert(7, 1)
    assert(tail_chain(&m, 7) == 1)
    assert(explicit_return(&m, 7) == 1)
    assert(bound_tail(&m, 7) == 1)
    assert(bound_local_then_return(&m, 7) == 1)
    assert(tail_with_cast(&m, 7) == 1)
    print("ok")
