//! expect-check-fail: cannot move out of global `name`

// §9.1 / D60 with D52 (§9.1c): the tail assignment yields a read of `name`
// under the ordinary move rules, and a global is never moved out of — the
// same error as the tail `name` itself. The compiler does not clone.
// A List global, not a str: a str global is read by copy (D111).

var name: List[i32] = List.new()
fn compute() -> List[i32]: [1, 2]
fn f -> List[i32]: name = compute()

fn main: print(f().len())
