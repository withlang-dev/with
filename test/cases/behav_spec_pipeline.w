//! expect-stdout: ok

// Spec conformance: pipeline and driver behavior
// Tracks docs/missing_features2.md section 1 (items 1-5)

use spec_harness
use CImport
use Driver

extern fn with_fs_write_file(path: str, data: str) -> i32
extern fn with_system(cmd: str) -> i32

fn test_01_check_runs_sema_type_mismatch() -> i32:
    let src = "fn main:\n    let x: i32 = \"nope\"\n"
    let rc = run_check_case("spec_pipeline_01_type_mismatch", src)
    expect_eq_i32(rc, CR_SEMA_ERROR(), "01 check runs sema for type mismatch")

fn test_02_check_runs_sema_name_resolution() -> i32:
    let src = "fn main:\n    not_defined_anywhere\n"
    let rc = run_check_case("spec_pipeline_02_name_resolution", src)
    expect_eq_i32(rc, CR_SEMA_ERROR(), "02 check runs sema for undefined names")

fn test_03_build_runs_post_sema_passes() -> i32:
    let src = "fn main:\n    var x = 1\n    let a = &mut x\n    let b = &x\n    println_i64(0)\n"
    let rc = run_build_case("spec_pipeline_03_borrow", src)
    expect_true(rc == CR_BORROW_ERROR() or rc == CR_SEMA_ERROR(), "03 build runs borrow/move checks")

fn test_04_c_import_extracts_decls() -> i32:
    let r = process_c_import("#include <stdio.h>")
    expect_true(CImportResult.decl_count(r) > 0, "04 c_import extracts declarations")

fn test_05_dotted_import_paths_map_to_dirs() -> i32:
    let root = ".with/spec_cases/spec_pipeline_05"
    assert(with_system("mkdir -p " ++ root ++ "/foo") == 0)
    let main_src = "use foo.bar\nfn main:\n    assert(imported_value() == 42)\n    println(\"ok\")\n"
    let mod_src = "fn imported_value() -> i32:\n    42\n"
    assert(with_fs_write_file(root ++ "/main.w", main_src) == 0)
    assert(with_fs_write_file(root ++ "/foo/bar.w", mod_src) == 0)
    var d = Driver.new(MODE_RUN(), root ++ "/main.w")
    let rc = Driver.compile_and_run(d)
    expect_eq_i32(rc, CR_OK(), "05 dotted imports resolve as foo/bar.w")

fn main:
    var failures = 0
    failures = failures + test_01_check_runs_sema_type_mismatch()
    failures = failures + test_02_check_runs_sema_name_resolution()
    failures = failures + test_03_build_runs_post_sema_passes()
    failures = failures + test_04_c_import_extracts_decls()
    failures = failures + test_05_dotted_import_paths_map_to_dirs()
    finalize_failures(failures)
