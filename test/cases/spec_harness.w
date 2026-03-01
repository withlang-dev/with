// Shared helpers for spec conformance tests.

use Driver

extern fn with_fs_write_file(path: str, data: str) -> i32
extern fn with_system(cmd: str) -> i32

pub fn ensure_spec_dirs() -> void:
    let mk = with_system("mkdir -p .with/spec_cases .with/build")
    assert(mk == 0)

pub fn write_case(name: str, src: str) -> str:
    ensure_spec_dirs()
    let path = ".with/spec_cases/" ++ name ++ ".w"
    let wr = with_fs_write_file(path, src)
    assert(wr == 0)
    path

pub fn run_check_case(name: str, src: str) -> i32:
    let path = write_case(name, src)
    var d = Driver.new(MODE_CHECK(), path)
    Driver.run_pipeline(d)

pub fn run_run_case(name: str, src: str) -> i32:
    let path = write_case(name, src)
    var d = Driver.new(MODE_RUN(), path)
    Driver.compile_and_run(d)

pub fn run_build_case(name: str, src: str) -> i32:
    let path = write_case(name, src)
    let exe = ".with/build/spec_" ++ name
    var d = Driver.new(MODE_BUILD(), path)
    Driver.compile_to_c(d, exe)

pub fn expect_eq_i32(actual: i32, expected: i32, label: str) -> i32:
    if actual == expected:
        println("PASS " ++ label)
        return 0
    println("FAIL " ++ label ++ " (expected " ++ i32_to_str(expected) ++ ", got " ++ i32_to_str(actual) ++ ")")
    1

pub fn expect_true(cond: bool, label: str) -> i32:
    if cond:
        println("PASS " ++ label)
        return 0
    println("FAIL " ++ label)
    1

pub fn finalize_failures(failures: i32) -> void:
    if failures == 0:
        println("ok")
        return
    println("spec failures: " ++ i32_to_str(failures))
    assert(false)
