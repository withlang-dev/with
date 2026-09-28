//! expect-stdout: ok

// #1678, D75 (§16.2b.5): the migrator translates a variadic C definition to
// the With form — `va_list ap; ... va_start(ap, n);` becomes
// `var ap = va_start()` where the list starts, `va_arg(ap, T)` becomes
// `ap.arg[T]()`, and `va_end` is the list's scope end — never a body
// omitted or a fixed-arity stand-in. A list started again after its va_end
// is a fresh binding. A K&R definition (`void stop()`) lists no parameters
// and is not variadic. The translation runs against the target's C library.
use pre_d_build_runner
use std.fs

fn main:
    let case_dir = p7_prepare_case("migrate_variadic_definitions", "va_defs")
    assert(mkdir_p(p7_join(case_dir, "lib")) == 0)
    p7_write(case_dir, "input.c", "#include <stdarg.h>\n#include <stdio.h>\n\nint sum(int n, ...) {\n    va_list ap;\n    int total = 0;\n    va_start(ap, n);\n    for (int i = 0; i < n; i++)\n        total += va_arg(ap, int);\n    va_end(ap);\n    return total;\n}\n\ndouble mean(int n, ...) {\n    va_list ap;\n    va_start(ap, n);\n    double total = 0;\n    for (int i = 0; i < n; i++)\n        total += va_arg(ap, double);\n    va_end(ap);\n    return n ? total / n : 0;\n}\n\nlong long pick(int which, ...) {\n    va_list args;\n    long long found = -1;\n    va_start(args, which);\n    for (int i = 0; i <= which; i++) {\n        const char *label = va_arg(args, const char *);\n        long long value = va_arg(args, long long);\n        if (i == which && label[0] != 0) found = value;\n    }\n    va_end(args);\n    va_start(args, which);\n    const char *first = va_arg(args, const char *);\n    va_end(args);\n    return found * 10 + (first[0] == 'a');\n}\n\nint format_into(char *buffer, int size, const char *format, ...) {\n    va_list ap;\n    va_start(ap, format);\n    int written = vsnprintf(buffer, size, format, ap);\n    va_end(ap);\n    return written;\n}\n\nint calls;\nvoid stop() { calls++; }\n")
    let migrated = p7_run(case_dir, "va_defs_migrate", "migrate\0input.c\0--no-c-export\0-o\0lib/va_defs.w\0")
    p7_assert_success(migrated, "migrate variadic definitions")
    let source = read_file(p7_join(case_dir, "lib/va_defs.w")).unwrap()
    assert(source.contains("unsafe fn sum(__param_n: c_int, ...) -> c_int"))
    assert(source.contains("var __local_ap: c_va_list = va_start()"))
    assert(source.contains("__local_ap.arg[c_int]()"))
    assert(source.contains("__local_ap.arg[f64]()"))
    assert(source.contains("var __local_args_1: c_va_list = va_start()"))
    assert(source.contains("fn stop() -> Unit"))
    assert(not source.contains("fn stop(...)"))
    assert(not source.contains("va_end"))
    assert(not source.contains("with_va_"))
    p7_write(case_dir, "src/main.w", "use va_defs\nfn main:\n    var buffer: [64]i8 = [0; 64]\n    unsafe:\n        assert(sum(4, 1, 2, 3, 36) == 42)\n        assert(mean(4, 1.0, 2.0, 3.0, 6.0) == 3.0)\n        assert(pick(1, \"a\\0\" as *const i8, 5 as i64, \"b\\0\" as *const i8, 9 as i64) == 91)\n        assert(format_into(&raw mut buffer as *mut i8, 64, \"%d-%s-%.2f\\0\" as *const i8, 42, \"x\\0\" as *const i8, 0.5) == 9)\n    stop()\n    print(\"variadic ok\")\n")
    let executed = p7_run(case_dir, "va_defs_run", "run\0src/main.w\0")
    p7_assert_success(executed, "run the migrated variadic definitions")
    assert(executed.stdout.contains("variadic ok"))
    print("ok")
