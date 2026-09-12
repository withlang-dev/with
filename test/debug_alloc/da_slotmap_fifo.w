//! expect-debug-alloc: leak count=0

use std.collections

var DROPS = 0
type Item { text: str }
impl Drop for Item:
    move fn drop: DROPS = DROPS + 1

fn empty:
    let map = SlotMap[Item].new()
    assert(map.len() == 0)

fn filled_and_reused:
    var map = SlotMap[Item].new()
    let handles: Vec[Handle[Item]] = Vec.new()
    for i in 0..128: handles.push(map.insert(Item { text: f"item {i}" }))
    let removed = map.remove(handles[3]).unwrap()
    assert(removed.text == "item 3")
    assert(DROPS == 0)
    removed.drop()
    let reused = map.insert(Item { text: "reused".clone() })
    assert(not map.contains(handles[3]) and map.contains(reused))
    let replaced = map.replace(handles[7], Item { text: "replacement".clone() }).unwrap()
    assert(replaced.text == "item 7")
    replaced.drop()
    assert(DROPS == 2)

fn main:
    empty()
    assert(DROPS == 0)
    filled_and_reused()
    assert(DROPS == 130)
