//! expect-stdout: a 5 6
//! expect-stdout: a 6 5
//! expect-stdout: b bee 7
//! expect-stdout: b bee! 8

// #1457: `Self { .. }` inside a module's impl or dotted method is that
// module's declaration, even when another module declares a type of the
// same name (§18.1). Sema left the literal untyped and MirLower resolved it
// by name to the newest `Item`, so module a's literal was built as module
// b's type (`a 5 0` / `a 0 0`).
use issue1457.ca
use issue1457.cb

fn main:
    let a = new_a()
    print(show_a(&a))
    print(show_a(&a.twin_a()))
    let b = new_b()
    print(show_b(&b))
    print(show_b(&b.twin_b()))
