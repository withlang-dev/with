//! expect-error: cannot mutate `value` while `view` is a live view into it
// D22 acceptance cell, promoted 2026-10-18 (the matrix's metadata follows).
// owner-stage: 4
// required-verdict: check-fail at `value = 124`
// exact-type: explicit `Option[&i32]` unwrap gives `view: &i32`
// expected-diagnostic: cannot mutate `value` while `view` is a live view into it
// origin-set: construction and unwrap preserve `{value}` without a collection producer
// drop-behavior: rejection precedes codegen; no owner is duplicated

fn main:
    var value = 123
    let carrier: Option[&i32] = Some(&value)
    let view = carrier.unwrap()
    value = 124
    assert(view == 123)
