//! expect-stdout: ok

// #1229: the typed MIR validator rejects an `aggregate` assigned to a
// slice-typed place. The MIR is built by hand: the source path that once
// produced it (an array literal passed to a `[]T` parameter) now types the
// literal as its array and slices a statement temporary.

use MirValidationTests

fn main:
    mir_test_slice_aggregate()
    print("ok")
