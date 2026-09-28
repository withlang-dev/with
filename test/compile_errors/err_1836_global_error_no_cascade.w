//! expect-error: integer literal does not fit expected type
//! expect-check-fail-not: missing return
//! expect-check-fail-not: bitwise operator requires integer operands

// #1836: an error in one global's initializer left every later global
// untyped (check_top_level_let_values returned at the first error), so each
// use of one reported a false error elsewhere.
let SMALL: u8 = 300
let KEEP = 0
let A = 8
let B = 16

fn verdict(k: i32) -> i32:
    if k > 3:
        return 1
    KEEP

fn main:
    var bits = 0
    bits = bits | (if verdict(2) == 0: A else: B)
    print(f"{bits}")
