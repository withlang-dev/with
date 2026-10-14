//! expect-error: `index_of` expects 1 argument(s), found 2

// #2358: a builtin method called with more arguments than its declared
// BuiltinSigs row is a diagnostic at the call, not an ICE in MIR lowering.

fn main:
    let s = "abcabc"
    print(s.index_of("b", 2))
