//! expect-stdout: ok

// #1627: the typed MIR validator rejects an enum aggregate that stores a
// value into a `&T` payload slot (a missing borrow). The MIR is built by
// hand: the source path that produced it (`Option[&Ctx].Some(ctx)`) now
// lowers the borrow.

use MirValidationTests

fn main:
    mir_test_enum_aggregate_missing_borrow()
    print("ok")
