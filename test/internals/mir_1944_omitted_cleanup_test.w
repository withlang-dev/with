//! expect-stdout: ok

use MirValidationTests

fn main:
    mir_test_omitted_cleanup()
    mir_test_constant_cleanup()
    print("ok")
