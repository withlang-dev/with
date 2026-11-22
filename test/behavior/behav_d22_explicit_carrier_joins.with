// D22 acceptance cell, promoted 2026-10-18 (the matrix's metadata follows).
// owner-stage: 3
// required-verdict: compile-and-run with one order-independent join rule
// exact-type: all-reference join is `&i32`; owned-anchor and expected-type joins are `i32`
// expected-diagnostic: none
// origin-set: `borrowed` has `{left, right}`; owned joins have `{}`
// drop-behavior: scalar-only fixture; each materialized arm is copied once

fn main:
    let left = 121
    let right = 122
    let use_left = true
    let borrowed = if use_left: &left else: &right
    let anchored = if use_left: borrowed else: 123
    let pinned: i32 = if use_left: &left else: &right
    assert(borrowed == 121)
    assert(anchored == 121)
    assert(pinned == 121)
