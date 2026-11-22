//! expect-stdout: hello
//! expect-stdout: 7 1
//! expect-stdout: 7
//! expect-stdout: 5

// #1903 (§21.1 rule 6, spec v7.18): `from static` states a view of static
// data — no parameter or global origin, so a write of a global while it is
// live is fine; on a return holding several views the clause lists the
// union of their origins; `a.b` names a module-qualified global.

use lib.issue1903b.counters as counters

var G: List[i32] = List.new()

fn greeting() -> &str from static: "hello"

fn both(a: &List[i32]) -> (&i32, &i32) from a, G: (&a[0], &G[0])

fn maybe(a: &List[i32], c: bool) -> Option[&i32] from a, G:
    if c: Some(&a[0]) else: Some(&G[0])

fn total_head() -> &i32 from counters.TOTAL: &counters.TOTAL[0]

fn main:
    let s = greeting()
    G.push(1)
    print(s)
    var x: List[i32] = List.new()
    x.push(7)
    let (p, q) = both(&x)
    print(f"{*p} {*q}")
    print(*maybe(&x, true).unwrap())
    counters.TOTAL.push(5)
    print(*total_head())
