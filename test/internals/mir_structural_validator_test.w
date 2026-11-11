//! expect-stdout: ok

// #984, #989: the structural validator refuses a body with no block, a goto
// out of range, and a switch whose default is the entry block (one
// contract for both backends: a switch default is a block after bb0).

use MirValidationTests

fn main:
    mir_test_structural_validator()
    print("ok")
