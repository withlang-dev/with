//! expect-stdout: ok

use c_import("stdlib.h")

fn test_modeled_value_c_import_functions_callable_directly:
    assert(abs(-42) == 42)

fn test_raw_c_import_functions_require_unsafe:
    unsafe { free(null) }

fn test_raw_pointer_operations_still_require_unsafe:
    var value = 0
    let p = (&raw mut value) as *mut i32
    unsafe { *p = 42 }
    assert(value == 42)

fn main:
    test_modeled_value_c_import_functions_callable_directly()
    test_raw_c_import_functions_require_unsafe()
    test_raw_pointer_operations_still_require_unsafe()
    print("ok")
