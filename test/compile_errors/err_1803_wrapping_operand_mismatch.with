//! expect-error: the right operand of a wrapping or saturating operator is `i32`

// §4.2.3/§4.2.6: a wrapping operator computes at its left operand's type; an
// i32 does not convert to u64 implicitly. It was sign-extended silently.
fn main:
    var h: u64 = 7
    let k: i32 = -1
    h = h +% k
    print(f"{h}")
