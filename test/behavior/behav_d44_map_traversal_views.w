//! expect-stdout: alpha beta
//! expect-stdout: [1, 2]
//! expect-stdout: alpha=1 beta=2
//! expect-stdout: [2, 4]
//! expect-stdout: [5, 4]
//! expect-stdout: x yy
//! expect-stdout: ["a1", "b2"]
//! expect-stdout: a b
// D44 (#2183, #2184, #2185): traversal observes. keys(), values() and iter()
// are concrete ephemeral iterators of views; an owned collection is cloned
// where it is wanted; `for` and a comprehension clause over a map or a set
// step its iter(). D96: a HashMap or HashSet walks in insertion order.
use std.collections

var m: HashMap[str, i32] = HashMap.new()
m.insert("alpha".to_owned(), 1)
m.insert("beta".to_owned(), 2)

let names = m.keys() |> map(it.clone()) |> collect[Vec]()
print(names.join(" "))
let counts = m.values() |> map(it.clone()) |> collect[Vec]()
print(f"{counts:?}")
let entries = m.iter() |> map(e => f"{e.0}={e.1}") |> collect[Vec]()
print(entries.join(" "))

let doubled = [v * 2 for (k, v) in m]
print(f"{doubled:?}")
let lengths = [k.len() for k in m.keys()]
print(f"{lengths:?}")

var s: HashSet[str] = HashSet.new()
s.insert("x".to_owned())
s.insert("yy".to_owned())
var seen = ""
for w in s: seen = seen ++ (if seen.len() > 0: " " else: "") ++ w
print(seen)

let bt: BTreeMap[str, i32] = ["b": 2, "a": 1]
let pairs = [f"{k}{v}" for (k, v) in bt]
print(f"{pairs:?}")
let bt_keys = bt.keys() |> collect[Vec]()
print(f"{bt_keys[0]} {bt_keys[1]}")
