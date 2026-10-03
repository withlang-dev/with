//! expect-error: `pick` returns a view derived from `b`, which its `from` clause does not name

// #1903 (§21.1 rule 6, spec v7.18): the union rule through `Option`: either
// arm's view is an origin of the returned value.

fn pick(a: &Vec[i32], b: &Vec[i32], c: bool) -> Option[&i32] from a:
    if c: Some(&a[0]) else: Some(&b[0])

fn main:
    var x: Vec[i32] = Vec.new()
    x.push(1)
    print(*pick(&x, &x, true).unwrap())
