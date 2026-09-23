//! expect-check-fail: cannot move out of global `name`

// §9.1 / D60: an arm of a tail `if` under a declared return is the same rule
// as the body's own tail — a read of the global, which D52 forbids moving.
// (#1339 returned the right-hand side while `name` kept it: a double free.)

var name: str = ""
fn pick(p: bool) -> str:
    if p: name = "yes".clone() else: name = "no".clone()

fn main: print(pick(true))
