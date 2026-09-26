//! expect-stdout: ok

use c_import("static inline int calculate(int value) { return value + 1; }")
c facade arithmetic:
    // Verified from the complete body above: no foreign callback runs.
    fn calculate
        callbacks none
fn main:
    assert(calculate(6) == 7)
    print("ok")
