//! expect-stdout: ok

use MirValidationTests

fn main:
    mir_test_maybe_uninit_drop()
    print("ok")
