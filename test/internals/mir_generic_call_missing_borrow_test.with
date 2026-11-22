//! expect-stdout: ok

// #1443: the typed MIR validator rejects a monomorphized generic call that
// passes a value where the callee's parameter is a reference to it. The MIR
// is built by hand: the source path that produced it (a generic receiver
// autoderef'd through `&Box`) now borrows the place it reached.

use MirValidationTests

fn main:
    mir_test_generic_call_missing_borrow()
    print("ok")
