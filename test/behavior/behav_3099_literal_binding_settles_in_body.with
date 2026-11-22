//! expect-stdout: 12
//! expect-stdout: a,b
//! expect-stdout: 3
// #3099: a `let xs = []` whose first use names the element type is decided
// by re-checking its own body (the settle loop D126's int locals use), not
// by a second Sema over the whole module. Three shapes in one body: a push
// of an integer expression (a weak demand, then the typed one from the
// loop), a push of a str, and a binding passed to a parameter.
fn count(xs: &List[i64]) -> isize: xs.len()

fn main:
    let xs = []
    for i in 0..4: xs.push(i * 2)
    var total = 0
    for x in xs: total = total + x
    print(f"{total}")
    let names = []
    names.push("a")
    names.push("b")
    print(names.join(","))
    let ys = []
    ys.push(7)
    ys.push(8)
    ys.push(9)
    print(f"{count(ys)}")
