//! expect-error: `len` takes no arguments, found 1

// #2358: a zero-argument builtin given an argument is a diagnostic at the
// call, not an ICE in MIR lowering (no BuiltinSigs row exists for it).

fn main:
    let s = "abc"
    print(s.len(1))
