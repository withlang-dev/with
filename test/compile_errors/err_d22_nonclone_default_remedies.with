//! expect-error: `??` would need to copy a `Ticket`, which is not Copy
//! expect-check-fail: help: borrow the owned side with `&`
//! expect-check-fail-not: .clone()
// D22 acceptance cell, promoted 2026-10-18 (the matrix's metadata follows).
// owner-stage: 8
// required-verdict: check-fail at the `??` join
// exact-type: success is `&Ticket`; default is owned `Ticket`
// expected-diagnostic: `??` would need to copy a `Ticket`, which is not Copy; do not suggest `.cloned()`
// origin-set: no result is formed; success would have `{tickets}`
// drop-behavior: rejection precedes codegen; `tickets` retains ownership

use std.collections.HashMap
resource type Ticket { number: i64 }

fn main:
    var tickets: HashMap[i32, Ticket] = HashMap.new()
    tickets.insert(1, Ticket { number: 67 })
    let owned = tickets.get(1) ?? Ticket { number: 68 }
    assert(owned.number == 67)
