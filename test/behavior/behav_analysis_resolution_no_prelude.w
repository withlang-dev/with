//! expect-stdout: ok

use pre_d_build_runner

// No prelude exposes the no-body/one-body boundary without library bodies.
// A single indirect-call body used to enter heap construction at root -1.
fn main:
    let dir = p7_prepare_case("analysis_resolution_no_prelude", "resolution_no_prelude")
    p7_write(dir, "src/empty.w", "extern fn foreign_call() -> i32\n")
    p7_write(dir, "src/single.w", "pub unsafe fn indirect(cb: extern \"C\" fn(c_va_list) -> i32, args: c_va_list) -> i32: cb(args)\n")
    p7_write(dir, "src/pair.w", "pub fn first() -> i32: 1\npub fn second() -> i32: first()\n")
    let empty = p7_run(dir, "resolution_no_prelude_empty", "analyze\0src/empty.w\0audit:resolution\0--no-prelude\0")
    p7_assert_failure_contains(empty, "analysis produced no MIR", "empty")
    for name in ["single", "pair"]:
        let result = p7_run(dir, "resolution_no_prelude_" ++ name, "analyze\0src/" ++ name ++ ".w\0audit:resolution\0--no-prelude\0")
        p7_assert_success(result, name)
        assert(result.stdout.contains("violations=0"))
    print("ok")
