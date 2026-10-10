//! expect-stdout: ok

// D75 (§16.2b.5): a With function defined with a trailing `...` has the C
// calling convention, so C calls it as it calls any variadic function: the
// arguments go where the target's C caller puts them (on Darwin arm64, all
// on the stack; on SysV x86_64 and AAPCS64, registers first), with C's
// default promotions (the `short`, `char` and `float` below arrive as int
// and double). `@[c_export]` defines the symbols the C harness declares.
use pre_d_build_runner
use std.sysinfo

fn main:
    let case_dir = p7_prepare_case("variadic_definition_from_c", "vd_from_c")
    p7_write(case_dir, "harness.c", "int vd_sum(int n, ...);\ndouble vd_mix(const char *shape, ...);\nint vd_call_sum(void) { return vd_sum(4, 10, 20, (short)12, (char)18); }\ndouble vd_call_mix(void) { return vd_mix(\"ifl\", -3, 0.75f, 4000000000LL); }\nint vd_call_many(void) { return vd_sum(10, 1, 3, 5, 7, 9, 11, 13, 15, 17, 64); }\n")
    p7_write(case_dir, "src/main.w", "extern fn vd_call_sum() -> i32\nextern fn vd_call_mix() -> f64\nextern fn vd_call_many() -> i32\n\n@[c_export(\"vd_sum\")]\nunsafe fn sum(n: i32, ...) -> i32:\n    var ap = va_start()\n    var total: i32 = 0\n    for i in 0..n:\n        total = total + ap.arg[i32]()\n    total\n\n// One argument per letter of `shape`: i = int, f = double, l = long long.\n@[c_export(\"vd_mix\")]\nunsafe fn mix(shape: *const i8, ...) -> f64:\n    var ap = va_start()\n    var total = 0.0\n    var i = 0\n    while shape[i] != 0:\n        if shape[i] == 'i' as i8: total = total + ap.arg[i32]() as f64\n        else if shape[i] == 'f' as i8: total = total + ap.arg[f64]()\n        else: total = total + (ap.arg[i64]() / 1000000000) as f64\n        i = i + 1\n    total\n\nfn main:\n    unsafe:\n        print(f\"{vd_call_sum()} {vd_call_mix()} {vd_call_many()}\")\n")
    let object = if os() == "Windows": "harness.obj" else: "harness.o"
    let binary = if os() == "Windows": "vd_from_c.exe" else: "vd_from_c"
    let compiled = p7_run(case_dir, "vd_from_c_cc", "cc\0-c\0harness.c\0-o\0" ++ object ++ "\0")
    p7_assert_success(compiled, "compile the C caller")
    let built = p7_run(case_dir, "vd_from_c_build", "build\0src/main.w\0--link-object\0" ++ object ++ "\0-o\0" ++ binary ++ "\0")
    p7_assert_success(built, "link the With variadic definitions with the C caller")
    let ran = p7_run_with_compiler(p7_join(case_dir, binary), case_dir, "vd_from_c_run", "")
    p7_assert_success(ran, "C calls the With variadic definitions")
    assert(ran.stdout.contains("60 1.75 145"))
    print("ok")
