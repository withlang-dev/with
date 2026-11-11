//! expect-stdout: 2 a b
//! expect-stdout: 3 6
//! expect-stdout: 1

// #3194 (§4.3c rule 1): a private module-level binding of an empty literal
// takes its type from its uses in the module's bodies, as a body-level one
// does from its function's. It was refused ("empty sequence literal
// requires expected type") unless the uses were top-level statements.
var names = []
var totals = []
var seen = []

fn note(s: &str): names.push(s.to_owned())

fn add(n: i32):
    totals.push(n)

fn total() -> i32:
    var sum = 0
    for t in totals: sum = sum + t
    sum

fn mark(id: i64): seen.push(id)

fn main:
    note("a")
    note("b")
    print(f"{names.len()} {names[0]} {names[1]}")
    add(1)
    add(2)
    add(3)
    print(f"{totals.len()} {total()}")
    mark(7)
    print(f"{seen.len()}")
