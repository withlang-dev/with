//! expect-debug-alloc: leak count=0

// #771 (the #729 loop shape): a statement temp materialized INSIDE a loop
// body must drop inside the body. Registered outward, its single drop landed
// at the loop exit: N iterations leaked N-1 temp values, and a ZERO-iteration
// loop dropped a never-initialized stack slot (the release-lane c_import SEGV
// — the slot held the previous call's dead-frame List header, so the "drop"
// freed the tracked-input vec's live buffer).
fn piece(n: i32) -> str:
    f"part{n}" ++ "!"

fn build(count: i32) -> str:
    var key = "k".to_owned()
    for i in 0..count:
        key = key ++ "|" ++ piece(i)
    key

fn main:
    // Zero iterations: the join must not drop uninitialized body temps.
    let empty = build(0)
    assert(empty == "k")
    // Three iterations: each body temp drops per iteration, none leak.
    let full = build(3)
    assert(full == "k|part0!|part1!|part2!")
    var w = "w".to_owned()
    var j = 0
    while j < 2:
        w = w ++ "-" ++ piece(j)
        j = j + 1
    assert(w == "w-part0!-part1!")
    print("ok")
