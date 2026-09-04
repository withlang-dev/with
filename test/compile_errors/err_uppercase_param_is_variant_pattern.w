//! expect-error: 'N' is neither a variant of the subject type nor a known constant; a binding starts with a lowercase letter, a unit variant is spelled .N (§9.7)

// An uppercase-initial identifier in a parameter list is a unit-variant
// pattern (`fn value(None: Option[i32])`), never a binding. Meant as a
// binding, it gets one error naming the rule — not "refutable parameter
// pattern" plus two "undefined variable"s.
fn scale(N: i32) -> i32: N * 2

fn main:
    print_i32(scale(3))
