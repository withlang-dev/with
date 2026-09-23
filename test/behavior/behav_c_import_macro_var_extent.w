//! expect-stdout: ok

// #1387: winnt.h's DEFINE_GUID(name, ...) expands to `EXTERN_C const GUID
// name`, a VarDecl whose spelling runs from `extern` on the #define line to
// `name` in the invocation. c_import read that whole span as the declaration's
// text, took the `=` of an earlier `#if _MSC_VER >= 1200` as its initializer
// and fed the C expression parser 373 KB of header: bzip2 and libcurl grew to
// 29 GB on Windows and died with a silent exit 99. A var without an
// initializer imports as `extern let` whatever lies between its macro and its
// use, so four times the filler must cost about the same, not ~60x (old: 1.4 s
// at 200 lines, 82 s at 800). Macro-built vars that do have initializers,
// and initializers holding comparisons, keep their values.

use pre_d_build_runner
use std.time

fn header(filler: i32) -> str:
    var h = StringBuilder.new()
    h.push_str("typedef struct _GUID { unsigned long d1; unsigned short d2; } GUID;\n")
    h.push_str("#define EXTERN_C extern\n")
    h.push_str("#if 1 >= 0\n#endif\n")
    for i in 0..filler:
        h.push_str(f"#define M{i}(a) ((a) * {i} + 1) - ((a) << 2) * 3 / 4\n")
    h.push_str("#define DEFINE_GUID(name, l, w) EXTERN_C const GUID name\n")
    h.push_str("DEFINE_GUID(G0, 0x1, 0x1);\n")
    h.push_str("#define DECLARE_K(name, v) static const int name = v\n")
    h.push_str("DECLARE_K(K0, 7);\n")
    h.push_str("static const int K1 = 3 >= 2;\n")
    h.push_str("static const int K2 = (1 <= 2) + 5;\n")
    h.to_str()

fn check_seconds(case_dir: &str, filler: i32) -> f64:
    p7_write(case_dir, f"src/guid{filler}.h", header(filler))
    // G0 is referenced only to prove it imported with its declared type.
    p7_write(case_dir, f"src/use{filler}.w", f"use c_import(\"guid{filler}.h\")\nfn main: print(f\"{{G0.d2}}\")\n")
    let start = now_ns()
    let run = p7_run(case_dir, f"c_import guid var after {filler} lines", f"check\0src/use{filler}.w\0")
    p7_assert_success(run, f"c_import guid var after {filler} lines")
    (now_ns() - start) as f64 / 1000000000.0

fn main:
    let case_dir = p7_prepare_case("c_import_macro_var_extent", "macrovarextent")
    let small = check_seconds(case_dir, 200)
    let large = check_seconds(case_dir, 800)
    if large > small * 4.0 + 1.0:
        eprint(f"200 filler lines: {small}s, 800: {large}s")
        assert(false)
    p7_write(case_dir, "src/main.w", "use c_import(\"guid200.h\")\nfn main:\n    assert(K0 == 7)\n    assert(K1 == 1)\n    assert(K2 == 6)\n    print(\"values\")\n")
    let run = p7_run(case_dir, "c_import macro var values", "run\0src/main.w\0")
    p7_assert_success(run, "c_import macro var values")
    assert(run.stdout.contains("values"))
    print("ok")
