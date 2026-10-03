//! expect-stdout: ok

// #1991: the ownership validator refuses a read through a local every path
// reaching it dropped. The pre-#1968 lowering of `let t = table();
// t[id].arity` read the element after `drop(t)`, the seed-built stage1's
// math_fn_arity panicked "index out of bounds", and validate-all said ok.

use MirValidationTests

fn main:
    mir_test_read_after_drop()
    print("ok")
