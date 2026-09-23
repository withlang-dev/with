//! expect-stdout: ok

// #1455: the typed MIR validator rejects an enum aggregate whose variant is
// not an index of the enum. The MIR is built by hand: the source path that
// produced it (a payload discriminant enum built with its discriminant as the
// variant) now lowers the variant index.

use MirValidationTests

fn main:
    mir_test_enum_aggregate_variant_index()
    print("ok")
