//! expect-stdout: ok

// #1993: the ownership validator refuses a read of an owned local every path
// moved out (a task handle read after the join_cleanup that released it).

use MirValidationTests

fn main:
    mir_test_moved_owned_read()
    print("ok")
