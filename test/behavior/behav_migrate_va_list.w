//! expect-stdout: ok

// #1104: migration preserves va_list identity, aliases, and pointer depth.
// The generated variadic body must also run against the target's C library.
use pre_d_build_runner
use std.fs

fn main:
    let case_dir = p7_prepare_case("migrate_va_list", "va_list_test")
    assert(mkdir_p(p7_join(case_dir, "lib")) == 0)
    p7_write(case_dir, "input.c", "#include <stdarg.h>\n#include <stdio.h>\ntypedef int my_va_list_counter;\ntypedef va_list forwarded_arguments;\ntypedef va_list *argument_pointer;\nmy_va_list_counter counter(void) { return 7; }\nint forward(char *buffer, const char *format, forwarded_arguments args) { return vsnprintf(buffer, 128, format, args); }\nint forward_pointer(char *buffer, const char *format, argument_pointer args) { return forward(buffer, format, *args); }\nint format_text(char *buffer, const char *format, ...) { va_list args; va_start(args, format); int result = forward_pointer(buffer, format, &args); va_end(args); return result; }\n")
    let migrated = p7_run(case_dir, "va_list_migrate", "migrate\0input.c\0--no-c-export\0-o\0lib/va_sample.w\0")
    p7_assert_success(migrated, "migrate va_list aliases and explicit pointers")
    let source = read_file(p7_join(case_dir, "lib/va_sample.w")).unwrap()
    assert(source.contains("fn counter() -> c_int"))
    assert(source.contains("__param_args: c_va_list"))
    assert(source.contains("__param_args: *mut c_va_list"))
    assert(source.contains("__local_args: c_va_list"))
    // Macro type probes use typeof wrappers. Decomposing those wrappers
    // directly loses array macros and changes void pointers into i8 pointers.
    p7_write(case_dir, "macro_shapes.c", "#define PREFIX \"va\"\n#define PROJECT_TEXT PREFIX \"list\"\n#define PROJECT_NULL ((void *)0)\nint value(void) { return PROJECT_TEXT[0]; }\n")
    let shapes = p7_run(case_dir, "va_list_macro_shapes", "migrate\0macro_shapes.c\0--no-c-export\0-o\0lib/macro_shapes.w\0")
    p7_assert_success(shapes, "preserve macro probe array and pointer shapes")
    let shape_source = read_file(p7_join(case_dir, "lib/macro_shapes.w")).unwrap()
    assert(shape_source.contains("PROJECT_TEXT: [7]c_char"))
    assert(shape_source.contains("PROJECT_NULL: *mut c_void = null"))
    p7_write(case_dir, "src/main.w", "use va_sample\nfn main:\n    var buffer: [128]i8 = [0; 128]\n    let expected = \"17 2.5 23 31 41 43 47 53 59 61\"\n    unsafe:\n        assert(counter() == 7)\n        assert(format_text(&raw mut buffer as *mut i8, \"%d %.1f %d %d %d %d %d %d %d %d\\0\" as *const i8, 17, 2.5 as f64, 23, 31, 41, 43, 47, 53, 59, 61) == expected.len())\n    for i in 0..expected.len() as i32:\n        assert(buffer[i] == expected[i] as i8)\n    assert(buffer[expected.len() as i32] == 0)\n    assert(alignof[c_va_list]() == 8)\n    print(\"formatted ok\")\n")
    let executed = p7_run(case_dir, "va_list_run", "run\0src/main.w\0")
    p7_assert_success(executed, "run migrated va_list across pointer and value calls")
    assert(executed.stdout.contains("formatted ok"))
    print("ok")
