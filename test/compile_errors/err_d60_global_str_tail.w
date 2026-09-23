//! expect-check-fail: cannot move out of global `name`

// §9.1 / D60 with D52 (§9.1c): the tail assignment yields a read of `name`
// under the ordinary move rules, and a global is never moved out of — the
// same error as the tail `name` itself. The compiler does not clone.

var name: str = ""
fn compute: "hi".clone() ++ "!"
fn f -> str: name = compute()

fn main: print(f())
