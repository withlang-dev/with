//! expect-stdout: a 1111111111111 2222222222222 3333333333333
//! expect-stdout: b bee 7 10
//! expect-stdout: a 2222222222222 1111111111111 3333333333333
//! expect-stdout: b bee! 8 12
//! expect-stdout: pair 2222222222222 5 bee 9
//! expect-stdout: shape 12 round
//! expect-stdout: kind a-hi b-lo
//! expect-stdout: vec 10 6
//! expect-stdout: opt a 1111111111111
//! expect-stdout: opt b bee

// #1446: two modules each declare `Item`, `Pair`, `Shape` and `Kind` with
// different layouts. Codegen named LLVM types by the bare declaration name,
// so both `Item`s shared one struct whose body the later declaration set:
// module a's i64 fields were read through b's `{ str, i32 }` layout
// (`a  1724130190`). Each declaration now has its own LLVM type.

use issue1446.a
use issue1446.b

fn main:
    let a = make_a()
    show_a(&a)
    let b = make_b()
    show_b(&b)
    show_a(&a.swap_a())
    show_b(&b.bump_b())
    let pa = pair_a()
    let pb = pair_b()
    print(f"pair {pa.first.y} {pa.n} {pb.first.s} {pb.n}")
    print(f"shape {area_a(&shape_a())} {area_b(&shape_b())}")
    print(f"kind {kind_name_a(kind_a())} {kind_name_b(kind_b())}")
    var ta: i64 = 0
    for e in items_a():
        ta = ta + e.x + e.y
    var tb: i64 = 0
    for e in items_b():
        tb = tb + e.k as i64 + e.s.len()
    print(f"vec {ta} {tb}")
    match maybe_a(true):
        Some(i) => print(f"opt a {i.x}")
        None => print("opt a none")
    match maybe_b(true):
        Some(i) => print(f"opt b {i.s}")
        None => print("opt b none")
