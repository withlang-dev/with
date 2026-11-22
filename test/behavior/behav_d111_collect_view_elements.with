//! expect-stdout: alpha beta
//! expect-stdout: 1 2
//! expect-stdout: a b
//! expect-stdout: 3 6

// #2271 (D111/D22 §6.2, D44): collecting an iterator of views into a List
// stores the values the views read — no `map(it.clone())` stage. A Copy
// view (`&str`, `&i32`) meets the List's owned-element demand by a copy,
// with or without an annotation, and through a `map(it)` adapter whose
// element crosses a callable value.
use std.collections.HashMap

fn names_of(m: &HashMap[str, i32]) -> List[str]:
    m.keys() |> map(it) |> collect[List]()

fn main:
    var m: HashMap[str, i32] = HashMap.new()
    m.insert("alpha", 1)
    m.insert("beta", 2)

    let names = names_of(&m)
    print(names.join(" "))

    let counts: List[i32] = m.values() |> collect[List]()
    print(f"{counts[0]} {counts[1]}")

    let keys = m.keys() |> collect[List]()
    print(f"{keys[0].slice(0, 1)} {keys[1].slice(0, 1)}")

    let vs: List[i32] = [1, 2, 3]
    let doubled = vs.iter() |> map(v => v * 2) |> collect[List]()
    print(f"{doubled.len()} {doubled[2]}")
