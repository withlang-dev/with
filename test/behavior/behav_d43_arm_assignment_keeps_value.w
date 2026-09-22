//! expect-stdout: ok

// §9.1 / D43 (Eric, 2026-09-22): an assignment is discarded only as a
// function's or closure's own body tail. A written arm of a tail `if`/`match`
// — bare or as an arm block's tail — keeps the place's type, so the arms join
// as values and the function returns the assigned value. (#1319 discarded
// every block's assignment tail; this is its narrowing.)

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

// The body's own tail is still discarded: §4.10 supplies i32.default().
fn body_tail -> i32:
    hits += 1
    seen = 50

// A closure body block is a body too.
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
    assert(body_tail() == 0)
    assert(seen == 50)
    assert(hits == 5)
    assert(via_closure() == 0)
    print("ok")
