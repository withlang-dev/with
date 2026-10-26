//! expect-stdout: ok

use MirValidationTests

fn main:
    mir_test_storage_dead_leak()
    print("ok")
