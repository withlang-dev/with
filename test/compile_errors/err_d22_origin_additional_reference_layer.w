//! expect-error: cannot mutate `value` while `nested` is a live view into it
// D22 acceptance cell, promoted 2026-10-18 (the matrix's metadata follows).
// owner-stage: 4
// required-verdict: check-fail at `value = 130`
// exact-type: matching `&(i32, &i32)` binds `nested: &&i32`
// expected-diagnostic: cannot mutate `value` while `nested` is a live view into it
// origin-set: `nested` preserves `{value}` through both shared-reference layers
// drop-behavior: rejection precedes codegen; no owner is duplicated

fn observe(_nested: &&i32): ()

fn main:
    var value = 129
    let inner = &value
    let pair = (1, inner)
    let subject = &pair
    let (_, nested) = subject
    value = 130
    observe(nested)
