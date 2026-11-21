//! expect-error: `rotate_left` expects 1 argument(s), found 2

// #2358: a builtin method called with more arguments than its declared
// BuiltinSigs row is a diagnostic at the call, not an ICE in MIR lowering.

fn main:
    let n: u32 = 6
    print(n.rotate_left(1, 2))
