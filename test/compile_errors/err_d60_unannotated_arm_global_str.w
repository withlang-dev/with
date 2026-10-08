//! expect-check-fail: cannot move out of global `name`

// §9.1 / D60 with D43: the arms of an unannotated tail `if` join as values,
// so the function returns a read of the global — moved out, which D52
// forbids.
// A Vec global, not a str: a str global is read by copy (D111).

var name: Vec[i32] = Vec.new()
fn pick(p: bool):
    if p: name = [1] else: name = [2]

fn main: print(pick(true).len())
