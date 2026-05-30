//! expect-stdout: ok

use c_import("stdio.h")

fn test_c_import_functions_callable_directly:
    let rc = puts(c"ok".ptr)
    assert(rc >= 0)

fn test_raw_pointer_operations_still_require_unsafe:
    var value = 0
    let p = (&raw mut value) as *mut i32
    unsafe { *p = 42 }
    assert(value == 42)

fn main:
    test_c_import_functions_callable_directly()
    test_raw_pointer_operations_still_require_unsafe()
