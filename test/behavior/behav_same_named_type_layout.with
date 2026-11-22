//! expect-stdout: a 1111111111111 2222222222222
//! expect-stdout: b bee 7

// #1446, the issue's repro: two modules declare `Item` with different
// fields. Before the fix this printed `a  1724130190` — module a's value
// read through module b's layout.

use issue1446.plain_a
use issue1446.plain_b

fn main:
    let a = make_a()
    show_a(&a)
    let b = make_b()
    show_b(&b)
