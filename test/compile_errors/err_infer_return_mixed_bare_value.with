//! expect-error: return type mismatch

// #653 guard: an unannotated fn that mixes a bare `return` with a
// `return <value>` must still error. Before the recording fix the value
// return was misread as bare and the conflict was silently swallowed as Unit.
fn bad(v: i32):
    if v == 0:
        return
    return true

fn main:
    let _ = bad(1)
