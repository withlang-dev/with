//! expect-stdout: ok

// #1915 (Eric, 2026-09-30): windows-x86_64 is the GNU environment — With's
// objects link the SDK's mingw-w64 UCRT runtime, not Visual Studio's. The
// module a windows_x86_64 compile emits names that triple; the MSVC spelling
// is no longer a target the driver accepts.

use pre_d_build_runner

fn main:
    let case_dir = p7_prepare_case("windows_target_is_gnu", "wintriple")
    p7_write(case_dir, "src/main.w", "fn main:\n    print(\"hi\")\n")
    let ir = p7_run(case_dir, "windows_triple_ir", "ir\0src/main.w\0--target=windows_x86_64\0")
    p7_assert_success(ir, "IR for windows_x86_64")
    if not ir.stdout.contains("target triple = \"x86_64-w64-windows-gnu\""):
        for line in ir.stdout.split("\n"):
            if line.starts_with("target triple"): eprint("have: " ++ line)
        assert(false)
    let msvc = p7_run(case_dir, "windows_msvc_ir", "ir\0src/main.w\0--target=x86_64-pc-windows-msvc\0")
    assert(msvc.rc != 0)
    print("ok")
