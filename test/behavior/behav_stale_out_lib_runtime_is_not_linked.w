//! expect-stdout: ok

// D30 / #761: a runtime object under the cwd's out/lib is a cache of the
// compiler's embedded one, valid byte for byte. A stale out/lib left in a
// checkout by another compiler generation must never be linked into a user
// program: `with run` in such a checkout died at link with an undefined
// with_vec_free_buffer_drop_origin (the old rt_core.o predated the symbol).
// The build alone may hand the compiler a prepared root, through
// WITH_OUT_DIR; this child runs without one, as a developer's shell does.
use pre_d_build_runner
use std.sysinfo

fn platform_object -> str:
    let host = if os() == "Darwin": "darwin" else if os() == "Windows": "windows" else: "linux"
    "rt_" ++ host ++ "_" ++ arch() ++ ".o"

fn main:
    let case = p7_prepare_case("stale_out_lib_runtime", "stale_out_lib_runtime")
    p7_write(case, "src/main.w", "fn main:\n    var v: Vec[str] = Vec.new()\n    v.push(\"a\".clone())\n    print(v.len())\n")
    // A complete-looking runtime root whose objects are not this compiler's.
    let stale = "stale runtime object from another compiler generation\n"
    p7_write(case, "out/lib/rt_core.o", stale)
    p7_write(case, "out/lib/cimport_stubs.o", stale)
    p7_write(case, "out/lib/" ++ platform_object(), stale)
    let run = p7_run_without_out_dir(case, "stale_out_lib_runtime_run", "run\0src/main.w\0")
    p7_assert_success(run, "run links the embedded runtime, not the stale out/lib")
    assert(run.stdout.contains("1"))
    print("ok")
