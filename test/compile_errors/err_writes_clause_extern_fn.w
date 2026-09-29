//! expect-check-fail: an extern fn has no With body to write globals: a `writes` clause belongs to a With function

// §21.1 rule 1 (Eric 2026-09-29): a `writes` clause states what a With
// body writes; an extern fn's body is foreign (its effects are modeled C's,
// D51), so a clause on one is refused.
var COUNT = 0

extern fn c_tick() -> i32 writes COUNT

fn main:
    print(COUNT)
