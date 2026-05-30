//! expect-stdout: ok

use c_import("stdio.h")
use c_import("time.h")
use c_import("limits.h")
use c_import("math.h", link: "m")
use c_import("typedef struct Hidden279 Hidden279;\nstruct Hidden279 { int value; };\ntypedef struct Holder279 { Hidden279 *hidden; int value; } Holder279;\n")

extern "C" fn strlen(s: *const u8) -> usize

fn test_c_import_functions_callable_directly:
    assert(printf(c"".ptr) == 0)

fn test_c_import_link_directive:
    assert(cos(0.0) == 1.0)

fn test_c_import_structs_are_usable:
    var t: time_t = 0
    let result = time(&raw mut t)
    assert(result != -1)

fn test_manual_extern_c_declaration:
    assert(unsafe { strlen(c"hello".ptr) } == 5usize)

fn test_c_import_forward_typedef_definition_order:
    var hidden = Hidden279 { value: 42 }
    let holder = Holder279 { hidden: &raw mut hidden, value: 7 }
    assert(holder.value == 7)
    assert(unsafe { holder.hidden.value } == 42)

fn test_c_import_constants_available:
    assert(INT_MAX == 2147483647)

fn main:
    test_c_import_functions_callable_directly()
    test_c_import_link_directive()
    test_c_import_structs_are_usable()
    test_manual_extern_c_declaration()
    test_c_import_forward_typedef_definition_order()
    test_c_import_constants_available()
    print("ok")
