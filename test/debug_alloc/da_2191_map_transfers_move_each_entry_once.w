//! expect-debug-alloc: leak count=0
//! expect-stdout: alpha
//! expect-stdout: 2
// D44 (#2191): a consuming traversal moves each owning key and value out
// exactly once; an iterator dropped early drops the entries it never
// yielded, and a drained map is still usable.
use std.collections

fn names() -> HashMap[str, str]:
    var m: HashMap[str, str] = HashMap.new()
    m.insert("alpha".to_owned(), "one".to_owned())
    m.insert("beta".to_owned(), "two".to_owned())
    m.insert("gamma".to_owned(), "three".to_owned())
    m

var keys = names().into_keys()
match keys.next():
    Some(k) => print(k)
    None => print("none")

var m = names()
let all = m.drain() |> collect[Vec]()
m.insert("delta".to_owned(), "four".to_owned())
m.insert("eps".to_owned(), "five".to_owned())
print(m.len())
