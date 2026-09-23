//! expect-stdout: ok

// §9.1 / D43 (Eric, 2026-09-22): a written arm of a tail `if`/`match` —
// bare or as an arm block's tail — keeps the place's type, so the arms join
// as values and the function returns the assigned value. D60 (2026-09-23)
// makes the body's own tail the same rule under a declared non-Unit return:
// it yields a read of its place; only an unannotated or `-> Unit` body
// discards its own tail assignment.

var seen: i32 = 0
var hits: i32 = 0

// Unannotated: both arm blocks end in an assignment, so both are i32.
fn pick(p: bool):
    if p:
        hits += 1
        seen = 10
    else:
        hits += 1
        seen = 20

// `-> i32` is a demanded join; the arms are values.
fn pick_match(n: i32) -> i32:
    match n:
        0 => { hits += 1; seen = 30 }
        _ =>
            hits += 1
            seen = 40

// D60: the body's own tail under `-> i32` is a read of `seen`.
fn body_tail -> i32:
    hits += 1
    seen = 50

// A closure body block under `fn() -> i32` is a body too.
fn via_closure() -> i32:
    var n = 0
    let f: fn() -> i32 = () =>
        n += 1
        n += 10
    f()

fn main:
    let a: i32 = pick(true)
    assert(a == 10)
    assert(pick(false) == 20)
    assert(pick_match(0) == 30)
    assert(pick_match(1) == 40)
    assert(seen == 40)
    assert(body_tail() == 50)
    assert(seen == 50)
    assert(hits == 5)
    assert(via_closure() == 11)
    print("ok")
