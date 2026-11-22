//! expect-stdout: ok

// #1444: the typed MIR validator rejects a discriminant enum's discriminant
// assigned to a place of another type. The MIR is built by hand: the source
// path that produced it (every discriminant lowered into an i32 temp) now
// types the temp as the enum's repr.

use MirValidationTests

fn main:
    mir_test_discriminant_repr_dest()
    print("ok")
