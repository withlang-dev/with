//! expect-stdout: ok

// #1230: the typed MIR validator rejects a call through a fn-typed value
// whose argument count is not the fn type's. The MIR is built by hand: the
// source path that once produced it (a parameter named like a builtin with
// a defaulted parameter) now lowers by the local's fn type.

use MirValidationTests

fn main:
    mir_test_indirect_call_arity()
    print("ok")
