//! expect-stdout: ok

use c_import("stdio.h")
use c_import("stdlib.h")
use c_import("time.h")
use c_import("limits.h")
use c_import("math.h", link: "m")
use c_import("string.h")
use c_import("typedef struct Hidden279 Hidden279;\nstruct Hidden279 { int value; };\ntypedef struct Holder279 { Hidden279 *hidden; int value; } Holder279;\n")
use c_import("typedef int (*With299Callback)(int);\ntypedef struct With299Holder { With299Callback cb; } With299Holder;\n")
use c_import("typedef struct WithKeywordFields { int opaque; int no_suspend; int c_import; int null; } WithKeywordFields;\n")
use c_import("#line 1 \"/usr/include/with_fake_unistd.h\"\nlong write(int fd, const void *buf, unsigned long nbyte);\n")

extern "C" fn atoi(s: *const u8) -> i32

fn test_c_import_functions_callable_directly:
    assert(abs(-42) == 42)

fn test_c_import_link_directive:
    assert(cos(0.0) == 1.0)

fn test_c_import_structs_are_usable:
    var t: time_t = 0
    let result = unsafe { time(&raw mut t) }
    assert(result != -1)

fn test_manual_extern_c_declaration:
    assert(unsafe { atoi(c"42".ptr) } == 42)

fn test_c_import_raw_c_string_literal_to_const_char_ptr:
    assert(strlen("hello") == 5usize)
    let s = f"abc{1}"
    assert(strlen(s) == 4usize)

fn test_c_import_raw_pointer_calls_require_unsafe:
    unsafe { free(null) }

fn test_c_import_forward_typedef_definition_order:
    var hidden = Hidden279 { value: 42 }
    let holder = Holder279 { hidden: &raw mut hidden, value: 7 }
    assert(holder.value == 7)
    assert(unsafe { holder.hidden.value } == 42)

fn test_c_import_constants_available:
    assert(INT_MAX == 2147483647)

fn test_c_import_callback_field_uses_extern_fn_pointer:
    let holder = With299Holder { cb: value => value + 1 }
    assert(holder.cb(41) == 42)

fn test_c_import_escapes_with_keyword_fields:
    let fields = WithKeywordFields { opaque_: 10, no_suspend_: 20, c_import_: 30, null_: 40 }
    assert(fields.opaque_ == 10)
    assert(fields.no_suspend_ == 20)
    assert(fields.c_import_ == 30)
    assert(fields.null_ == 40)

fn test_c_import_system_prelude_collision_is_omitted:
    write("")

fn main:
    test_c_import_functions_callable_directly()
    test_c_import_link_directive()
    test_c_import_structs_are_usable()
    test_manual_extern_c_declaration()
    test_c_import_raw_c_string_literal_to_const_char_ptr()
    test_c_import_raw_pointer_calls_require_unsafe()
    test_c_import_forward_typedef_definition_order()
    test_c_import_constants_available()
    test_c_import_callback_field_uses_extern_fn_pointer()
    test_c_import_escapes_with_keyword_fields()
    test_c_import_system_prelude_collision_is_omitted()
    print("ok")
