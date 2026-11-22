//! expect-stdout: ok

// #1814 (§2.3): the typed MIR validator rejects an `array_fill` of a
// non-Copy element — one evaluation copied into N slots is N owners of one
// value. The MIR is built by hand: MirLower now builds a non-Copy fill as a
// loop of evaluations, so no source program produces it.

use MirValidationTests

fn main:
    mir_test_non_copy_array_fill()
    print("ok")
