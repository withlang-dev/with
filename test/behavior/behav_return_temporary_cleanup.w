//! expect-stdout: ok

use pre_d_build_runner
use std.fs
use std.process

fn main:
    let root = p7_prepare_case("return_temporary_cleanup", "returntemporarycleanup")
    p7_write(root, "src/main.w", read_file(p7_abs("test/behavior/lib/temporary_exit_cases.w")).unwrap())
    // One build, then every mode runs that binary under the debug allocator
    // (`--debug-alloc` is WITH_DEBUG_ALLOC=1 for the program). Thirty
    // `with run`s compiled the same program thirty times and outlasted the
    // runner's 120 s limit on a stage compiler.
    let bin = root ++ "/out/temporary_exit_cases"
    let built = p7_run(root, "build", "build\0src/main.w\0-o\0" ++ bin ++ "\0")
    p7_assert_success(built, "build")
    let previous = env("WITH_ALLOC_NO_REUSE")
    let previous_debug = env("WITH_DEBUG_ALLOC")
    assert(set_env("WITH_ALLOC_NO_REUSE", "1") == 0)
    assert(set_env("WITH_DEBUG_ALLOC", "1") == 0)
    for mode in ["return", "normal", "try", "try-normal", "nested", "argument", "argument-normal", "branch", "branch-normal", "break", "continue", "user-try", "user-try-normal", "cancel", "coalesce-none", "coalesce-some", "coalesce-error", "coalesce-ok", "match-return", "match-normal", "match-none", "iflet-return", "iflet-normal", "iflet-none", "named-match-return", "named-iflet-return", "defer", "destructor", "errdefer", "user-errdefer"]:
        let result = p7_run_with_compiler(bin, root, mode, mode ++ "\0")
        p7_assert_success(result, mode)
        if not result.stderr.contains("debug-alloc: leak count=0"):
            eprint(mode ++ ": " ++ result.stderr)
            assert(false)
        assert(not result.stderr.contains("ledger full"))
    assert(set_env("WITH_DEBUG_ALLOC", previous_debug) == 0)
    assert(set_env("WITH_ALLOC_NO_REUSE", previous) == 0)
    print("ok")
