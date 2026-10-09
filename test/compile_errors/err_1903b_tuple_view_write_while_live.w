//! expect-check-fail: cannot mutate `G` while `p` is a live view into it

// #1903 (§21.1 rule 6, spec v7.18): a tuple of views carries the union of
// its views' origins, so writing G while a view from it is live is refused.

var G: List[i32] = List.new()

fn both(a: &List[i32]) -> (&i32, &i32) from a, G: (&a[0], &G[0])

fn main:
    G.push(1)
    var x: List[i32] = List.new()
    x.push(2)
    let (p, q) = both(&x)
    G.push(3)
    print(*p + *q)
