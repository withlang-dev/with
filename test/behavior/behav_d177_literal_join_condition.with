//! expect-stdout: join
//! expect-stdout: 3
//! expect-stdout: arm

// D177 (§4.2a) with D126: a condition whose values are all soft literals —
// a join of `1` and `0`, which is how a C comparison used as an integer
// migrates — is typed `i32` by the test and is true when nonzero.
fn main:
    if (if 2 > 1: 1 else: 0): print("join")
    var n = 3
    var steps = 0
    while (if n > 0: 1 else: 0):
        n -= 1
        steps += 1
    print(f"{steps}")
    let k = 2
    if (match k:
        2 => 1
        _ => 0): print("arm")
