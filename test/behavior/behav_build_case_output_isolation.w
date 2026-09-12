//! expect-stdout: ok

use pre_d_build_runner
use std.fs
use std.process
use std.sysinfo

fn main:
    let first = p7_prepare_case("output_isolation_first", "output_isolation_first")
    let second = p7_prepare_case("output_isolation_second", "output_isolation_second")
    let parent_out = p7_join(first, "parent-out")
    let saved_out = env("WITH_OUT_DIR").clone()
    assert(set_env("WITH_OUT_DIR", parent_out) == 0)
    p7_write(first, "src/main.w", "fn main: print(\"first\")\n")
    p7_write(second, "src/main.w", "fn main: print(\"second\")\n")
    p7_assert_success(p7_run(first, "output_isolation_first_build", "build\0src/main.w\0"), "first isolated build")
    assert(env("WITH_OUT_DIR") == parent_out)
    p7_assert_success(p7_run(second, "output_isolation_second_build", "build\0src/main.w\0"), "second isolated build")
    assert(env("WITH_OUT_DIR") == parent_out)
    assert(set_env("WITH_OUT_DIR", saved_out) == 0)
    let binary = if os() == "Windows": "out/src/main.exe" else: "out/src/main"
    assert(file_exists(p7_join(first, binary)))
    assert(file_exists(p7_join(second, binary)))
    assert(not file_exists(p7_join(parent_out, "src/main.o")))
    print("ok")
