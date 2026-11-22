//! expect-stdout: ok

// Comptime differential: HashMap insert/contains/len, and (#665) the
// Option-shaped get/remove surface — Some/None, unwrap, is_some/is_none,
// unwrap_or, and the map-untouched-on-miss remove contract.

use std.collections.HashMap
comptime fn map_battery(n: i32) -> i32:
    let m = HashMap[i32, i32].new()
    for i in 0..n:
        m.insert(i, i * 7)
    var acc = 0
    for i in 0..(n + 3):
        if m.contains(i):
            acc = acc + 1
        else:
            acc = acc + 50
    acc + m.len() as i32

comptime fn map_option_battery(n: i32) -> i32:
    // Scoped to the Option methods sema's raw-encoded-optional typing
    // accepts on get/remove results (unwrap/is_some/is_none): expect and
    // unwrap_or are rejected at check time on BOTH phases today. The
    // comptime evaluator already handles them for when sema catches up.
    let m = HashMap[i32, i32].new()
    for i in 0..n:
        m.insert(i, i * 7)
    var acc = 0
    for i in 0..(n + 3):
        let v = m.get(i)
        if v.is_some():
            acc = acc + v.unwrap()
        else:
            acc = acc + 1000
    acc = acc + m.remove(2).unwrap()
    let missing = m.remove(999)
    if missing.is_none():
        acc = acc + 5000
    acc + m.len() as i32

const CT_MAP: i32 = comptime map_battery(9)
const CT_MAP_OPT: i32 = comptime map_option_battery(9)

fn main:
    assert(CT_MAP == map_battery(9))
    assert(CT_MAP_OPT == map_option_battery(9))
    print("ok")
