//! expect-error: `both` returns a view of the global `G`, which its `from` clause does not name

// #1903 (§21.1 rule 6, spec v7.18): on a return type that holds several
// views, the clause lists the union of the origins of every view in it.

var G: Vec[i32] = Vec.new()

fn both(a: &Vec[i32]) -> (&i32, &i32) from a: (&a[0], &G[0])

fn main:
    G.push(1)
    var x: Vec[i32] = Vec.new()
    x.push(2)
    let (p, q) = both(&x)
    print(*p + *q)
