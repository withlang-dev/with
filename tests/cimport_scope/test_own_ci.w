// test_own_ci.w — Verify that a module that uses c_import can see its own c_import symbols.

use c_user
use c_import("<stdlib.h>")

extern fn with_eprintln(s: str) -> void

fn main:
    // abort is from <stdlib.h> which WE imported — should be visible
    let msg = c_user_greeting()
    with_eprintln(msg)
    with_eprintln("own c_import symbols visible — PASSED")
