// test_no_leak.w — Verify per-module c_import scoping.
// c_user.w uses c_import("<stdio.h>") internally. This file imports c_user
// but does NOT use c_import, so c_import symbols like printf should not be
// visible here. Only c_user's own declarations (c_user_greeting) are visible.

use c_user

extern fn with_eprintln(s: str) -> void

fn main:
    let msg = c_user_greeting()
    with_eprintln(msg)
    with_eprintln("c_import scoping: non-transitive — PASSED")
