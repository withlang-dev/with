//! expect-check-fail: cannot move out of global `name`

// §9.1 / D60: an arm of a tail `if` under a declared return is the same rule
// as the body's own tail — a read of the global, which D52 forbids moving.
// (#1339 returned the right-hand side while `name` kept it: a double free.)
// A List global, not a str: a str global is read by copy (D111).

type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): {}
var name: List[Tok] = List.new()
fn pick(p: bool) -> List[Tok]:
    if p: name = [Tok { id: 1 }] else: name = [Tok { id: 2 }]

fn main: print(pick(true).len())
