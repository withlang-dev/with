//! expect-error: if condition must be bool

// #654: a non-bool (here Unit) if condition must be rejected, not branched
// on at runtime.
fn g():
    print("side effect")

fn main:
    if g(): print("yes")
    else: print("no")
