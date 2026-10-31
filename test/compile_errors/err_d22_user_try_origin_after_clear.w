//! expect-error: cannot mutate `map` while `view` is a live view into it
// D22 acceptance cell, promoted 2026-10-18 (the matrix's metadata follows).
// owner-stage: 4
// required-verdict: check-fail at `map.clear()`
// exact-type: `Probe[&i32]` branches to `view: &i32`
// expected-diagnostic: cannot mutate `map` while `view` is a live view into it
// origin-set: user-defined `Try` preserves `{map}`
// drop-behavior: rejection precedes codegen; the map remains the sole owner

use std.traits.ControlFlow
use std.collections.HashMap
enum Probe[T]:
    Good(T)
    Bad(str)

impl[T] Try[T, str] for Probe[T]:
    fn branch(move self: Self) -> ControlFlow[str, T]:
        match self:
            Good(value) => ControlFlow.Continue(value)
            Bad(message) => ControlFlow.Break(message)

    fn from_break(message: str) -> Self:
        Bad(message)

fn observe_after_mutation() -> Probe[i32]:
    var map: HashMap[i32, i32] = HashMap.new()
    map.insert(1, 43)
    let carrier: Probe[&i32] = Probe.Good(map.get(1).unwrap())
    let view: &i32 = carrier?
    map.clear()
    Probe.Good(view)

fn main:
    let _ = observe_after_mutation()
