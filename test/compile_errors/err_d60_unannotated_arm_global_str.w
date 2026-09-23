//! expect-check-fail: cannot move out of global `name`

// §9.1 / D60 with D43: the arms of an unannotated tail `if` join as values,
// so the function returns a read of the global — moved out, which D52
// forbids.

var name: str = ""
fn pick(p: bool):
    if p: name = "yes".clone() else: name = "no".clone()

fn main: print(pick(true))
