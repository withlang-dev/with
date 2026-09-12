//! expect-stdout: ok

use MirValidationTests

fn main:
    mir_test_uninitialized_drop()
    print("ok")
