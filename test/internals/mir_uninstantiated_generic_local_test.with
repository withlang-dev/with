//! expect-stdout: ok

// #2108: the typed MIR validator rejects a local whose type is a generic
// declaration with no type arguments. The MIR is built by hand: Sema settles
// or rejects such a binding (#2103), so no source program produces it.

use MirValidationTests

fn main:
    mir_test_uninstantiated_generic_local()
    print("ok")
