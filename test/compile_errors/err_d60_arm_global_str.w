//! expect-check-fail: cannot move out of global `name`

// §9.1 / D60: an arm of a tail `if` under a declared return is the same rule
// as the body's own tail — a read of the global, which D52 forbids moving.
// (#1339 returned the right-hand side while `name` kept it: a double free.)
// A Vec global, not a str: a str global is read by copy (D111).

var name: Vec[i32] = Vec.new()
fn pick(p: bool) -> Vec[i32]:
    if p: name = [1] else: name = [2]

fn main: print(pick(true).len())
