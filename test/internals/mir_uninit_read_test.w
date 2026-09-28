//! expect-stdout: ok

// #1860: the ownership validator refuses a read of a local on a path that
// never initialized it. A value-position match's join read the result its
// no-arm path never wrote, and validate-all said ok.

use MirValidationTests

fn main:
    mir_test_uninit_read()
    print("ok")
