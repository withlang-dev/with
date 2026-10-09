//! expect-debug-alloc: leak count=0
// #2165: collecting an element whose key is already present is the insert
// of a duplicate. The key it carried and the entry it replaces are dropped,
// as `insert` drops them.
use std.collections.BTreeSet
use std.collections.BTreeMap

fn main:
    let names: List[str] = ["A".to_lower(), "A".to_lower(), "B".to_lower()]
    let set = names.iter() |> map(n => n.clone()) |> collect[HashSet[str]]()
    assert(set.len() == 2)
    let map = names.iter() |> map(n => (n.clone(), n.to_upper())) |> collect[HashMap[str, str]]()
    assert(map.len() == 2)
    let sorted = names.iter() |> map(n => n.clone()) |> collect[BTreeSet[str]]()
    assert(sorted.len() == 2)
    let ordered = names.iter() |> map(n => (n.clone(), n.to_upper())) |> collect[BTreeMap[str, str]]()
    assert(ordered.len() == 2)
