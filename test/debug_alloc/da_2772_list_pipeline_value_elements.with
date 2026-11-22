//! expect-debug-alloc: leak count=0
//! expect-stdout: b2! 2 3 a1|b2 5
// #2772: a List's map/filter/fold were codegen intrinsics that passed each
// element to the closure by a byte copy, a second owner of a str the list
// still held: `ys.map(it.to_owned())`, `ys.map(it.len())` and
// `ys.filter(it.len() > 0)` over a List[str] each freed every element twice.
// A List's adapters are its iterator's (D142): the closure sees a view, and
// collect copies a value out (D111, D139).
fn main:
    let ys = "a1 b2".split(" ")
    let bangs: List[str] = ys |> map(it ++ "!") |> collect[List]()
    let lens: List[isize] = ys |> map(it.len()) |> collect[List]()
    let kept: List[str] = ys |> filter(it.len() > 0) |> collect[List]()
    let owned: List[str] = ys |> map(it.to_owned()) |> collect[List]()
    let total = ys |> fold(0, (acc, s) => acc + s.len())
    print(f"{bangs[1]} {lens[0]} {kept.len() + 1} {owned.join("|")} {total + 1}")
