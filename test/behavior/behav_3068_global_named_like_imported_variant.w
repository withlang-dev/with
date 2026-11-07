//! expect-stdout: expected text
//! expect-stdout: true
//! expect-stdout: ok

// #3068: a module's own global named like a bare variant of an enum an
// imported module declares is the global (§18.2). MirLower read the
// variant for it in an f-string, in `assert` and as an `assert_eq`
// argument (an integer where Sema had typed a str).
use flags_mod_3068

let AFTER = "expected text"
let BEFORE = "before text"

fn main:
    let got = "expected" ++ " text"
    print(f"{AFTER}")
    print(f"{got == AFTER}")
    assert(BEFORE != AFTER)
    assert_eq(got, AFTER)
    print("ok")
