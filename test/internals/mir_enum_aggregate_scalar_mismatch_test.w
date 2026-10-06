//! expect-stdout: ok

// D103 (§4.9a): the typed MIR validator rejects an enum aggregate whose
// scalar payload slot receives a scalar of another width, signedness or
// kind. The MIR is built by hand: the source path that produced it
// (`Option[i64].Some(narrow)` from an `i32`) now casts the value first.

use MirValidationTests

fn main:
    mir_test_enum_aggregate_scalar_mismatch()
    print("ok")
