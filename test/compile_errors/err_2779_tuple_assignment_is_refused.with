//! expect-check-fail: cannot assign to a tuple: a tuple is a value, not a place
// #2779: `(a, b) = (b, a)` warned "cannot assign to a non-place
// expression" and then did nothing: the program printed `20 35`. A target
// that is no place is refused.
fn main:
    var a = 20
    var b = 35
    (a, b) = (b, a)
    print(f"{a} {b}")
