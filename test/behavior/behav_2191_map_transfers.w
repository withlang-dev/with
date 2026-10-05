//! expect-stdout: alpha=1 beta=2 gamma=3
//! expect-stdout: alpha beta gamma
//! expect-stdout: 1 2 3
//! expect-stdout: drained 2, left 0
//! expect-stdout: a=1 b=2
//! expect-stdout: a b
//! expect-stdout: 1 2
//! expect-stdout: drained 2, left 0
// D44 (#2191): the consuming traversals move each entry out once.
// into_iter/into_keys/into_values consume the map; drain leaves it empty.
// A HashMap walks in insertion order (D96), a BTreeMap in key order.
use std.collections

fn names() -> HashMap[str, i32]:
    var m: HashMap[str, i32] = HashMap.new()
    m.insert("alpha".to_owned(), 1)
    m.insert("beta".to_owned(), 2)
    m.insert("gamma".to_owned(), 3)
    m

fn tree() -> BTreeMap[str, i32]:
    var t: BTreeMap[str, i32] = BTreeMap.new()
    t.insert("b".to_owned(), 2)
    t.insert("a".to_owned(), 1)
    t

let entries = names().into_iter() |> map(e => f"{e.0}={e.1}") |> collect[Vec]()
print(entries.join(" "))
let keys: Vec[str] = names().into_keys() |> collect[Vec]()
print(keys.join(" "))
let values = names().into_values() |> map(v => f"{v}") |> collect[Vec]()
print(values.join(" "))
var m = names()
m.remove("gamma")
let drained = m.drain() |> collect[Vec]()
print(f"drained {drained.len()}, left {m.len()}")

let t_entries = tree().into_iter() |> map(e => f"{e.0}={e.1}") |> collect[Vec]()
print(t_entries.join(" "))
let t_keys: Vec[str] = tree().into_keys() |> collect[Vec]()
print(t_keys.join(" "))
let t_values = tree().into_values() |> map(v => f"{v}") |> collect[Vec]()
print(t_values.join(" "))
var t = tree()
let t_drained = t.drain() |> collect[Vec]()
print(f"drained {t_drained.len()}, left {t.len()}")
