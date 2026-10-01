//! expect-stdout: ok

use pre_d_build_runner

// A specialization, its signature and its parameters retain the imported
// declaration's source path instead of the caller's fallback path.
fn main:
    let dir = p7_prepare_case("analysis_generic_source_path", "genericpath")
    p7_write(dir, "src/helper.w", "pub unsafe fn load[T](p: *const T) -> T: *p\n")
    p7_write(dir, "src/main.w", "use helper\nfn main:\n    let value = 42\n    let p = &raw const value\n    print(unsafe { load(p) })\n")
    for reverse in [false, true]:
        let flags = if reverse: "--sema-body-order-reverse\0" else: ""
        let result = p7_run(dir, f"generic_source_path_{reverse}", "analyze\0" ++ flags ++ "src/main.w\0select:stage=sema,name~load__sema__\0")
        p7_assert_success(result, "generic source paths")
        assert(result.stdout.contains("\tsema\tsignature\t"))
        assert(result.stdout.contains("\tsema\tparameter\t"))
        assert(result.stdout.contains("\tsema\tspecialization\t"))
        for line in result.stdout.split("\n"):
            if line.contains("\tsema\tsignature\t") or line.contains("\tsema\tparameter\t") or line.contains("\tsema\tspecialization\t"):
                assert(line.contains("src/helper.w\t"))
    print("ok")
