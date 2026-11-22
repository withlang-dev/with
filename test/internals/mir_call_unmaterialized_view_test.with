//! expect-stdout: ok

// #2023: the typed MIR validator rejects a Copy view (`&i64`) passed where
// the callee's parameter is the owned i64, through a str intrinsic and a
// direct call. The MIR is built by hand: Sema now records the owned demand
// that materializes the view, so no source program produces it.

use MirValidationTests

fn main:
    mir_test_call_unmaterialized_view()
    print("ok")
