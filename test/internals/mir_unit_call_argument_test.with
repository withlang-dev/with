//! expect-stdout: ok

// #1180: the typed MIR validator rejects a Unit call argument whose callee
// parameter is not Unit. The MIR is built by hand: the source path that once
// produced it (an f-string over a Unit call) is now a Sema error.

use MirValidationTests

fn main:
    mir_test_unit_call_argument()
    print("ok")
