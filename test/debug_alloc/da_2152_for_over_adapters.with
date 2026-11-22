//! expect-debug-alloc: leak count=0
// #2152 (§13.1, §13.5, §13.6): every iterator adapter is a `for` iterable
// and a comprehension clause, a collection has `enumerate()`, and the
// elements a loop sees through one are views: nothing here is copied out
// of `names`, which still owns every element at the end.
fn a: "A".to_lower()

fn main:
    let xs: List[i32] = [1, 2, 3]
    let names: List[str] = [a(), "bc".to_lower(), a()]
    var seen = 0
    for (i, x) in xs.enumerate(): seen += i as i32 * x
    assert(seen == 8)
    var indexed = ""
    for (i, name) in names.enumerate(): indexed = indexed ++ f"{i}{name} "
    assert(indexed == "0a 1bc 2a ")
    var kept = 0
    for name in names.iter() |> filter(it.len() == 1): kept += name.len() as i32
    assert(kept == 2)
    var doubled = 0
    for x in xs.iter() |> map(it * 2): doubled += x
    assert(doubled == 12)
    var zipped = ""
    for (name, x) in names.iter() |> zip(xs.iter()): zipped = zipped ++ f"{name}{x}"
    assert(zipped == "a1bc2a3")
    var first_two = 0
    for x in xs.iter() |> take(2): first_two += x
    assert(first_two == 3)
    let lens = [(i, w.len()) for (i, w) in names.enumerate()]
    assert(lens.len() == 3 and lens[1].1 == 2)
    let through_views = [w.len() for w in names.iter_ref()]
    assert(through_views.len() == 3)
    assert(names.len() == 3 and names[1] == "bc")
