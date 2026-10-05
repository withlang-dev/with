//! expect-stdout: 6
//! expect-stdout: 3
//! expect-stdout: 2
//! expect-stdout: 2
//! expect-stdout: 7
//! expect-stdout: one
//! expect-stdout: 0

// #2144: an annotation that names a generic type without its arguments
// names the type, and the initializer decides the arguments. A collection
// literal builds the named collection (§4.3c), its elements deciding the
// element type; any other initializer must already be that generic type.
use std.collections.HashSet
use std.collections.HashMap
use std.collections.BTreeMap

type Pair[A, B] { first: A, second: B }

fn total(xs: &Vec[i32]): xs.iter() |> sum()

fn main:
    let xs: Vec = [1, 2, 3]
    print(total(xs))
    var names: Vec = ["a", "b"]
    names.push("c")
    print(names.len())
    let seen: HashSet = ["a", "b", "a"]
    print(seen.len())
    let ages: BTreeMap = ["ann": 30, "bob": 41]
    print(ages.len())
    let found: Option = Some(7)
    print(found ?? 0)
    let pair: Pair = Pair { first: 1, second: "one" }
    print(pair.second)
    let grown: Vec = Vec[str].new()
    print(grown.len())
