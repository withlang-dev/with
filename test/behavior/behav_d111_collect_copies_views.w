//! expect-stdout: 3 ab 3 a 2

use std.collections.HashSet

// D111 (#2271): a collect whose destination owns the values the iterator
// views copies each element — an inferred List under a `List[str]` return,
// an explicit `List[str]`, and a `HashSet[str]` — with no `.clone()`.
fn keys(xs: &List[str]) -> List[str]: xs.iter() |> map(it) |> collect[List]()

fn typed(xs: &List[str]) -> List[str]: xs.iter() |> collect[List[str]]()

fn set(xs: &List[str]) -> HashSet[str]: xs.iter() |> collect[HashSet[str]]()

fn main:
    let xs: List[str] = ["a", "b", "a"]
    let k = keys(&xs)
    let t = typed(&xs)
    print(f"{k.len()} {k[0]}{k[1]} {t.len()} {t[2]} {set(&xs).len()}")
