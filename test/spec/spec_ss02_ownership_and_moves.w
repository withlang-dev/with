// Spec test: Section 2 — Ownership and Moves (formerly 25.1)

// PASS: basic move
fn test_basic_move:
    var a = Vec.new()
    let b = a
    b.push(1)

// PASS: copy type
fn test_copy_type:
    let a: i32 = 5
    let b = a
    let c = a
    assert(c == 5)

// FAIL: use after move — needs expect-error test
// fn test_use_after_move:
//     let a = Vec.new()
//     let b = a
//     a.push(1)            // ERROR: use of moved value

// FAIL: use after move to function — needs expect-error test
// fn takes(v: Vec[i32]): ()
// fn test_use_after_move_to_fn:
//     let a = Vec.new()
//     takes(a)
//     a.len()              // ERROR: moved
