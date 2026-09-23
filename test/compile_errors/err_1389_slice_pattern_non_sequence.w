//! expect-error: a slice pattern requires an array, slice or Vec subject, found 'i32'

// #1389 (§9.7): a slice pattern matches a sequence. Against anything else
// its bindings used to be left untyped and MIR lowering failed later.
fn main:
    let n = 5
    match n:
        [a] => print(f"{a}")
        _ => print("other")
