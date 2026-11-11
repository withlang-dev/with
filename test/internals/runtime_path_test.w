//! expect-stdout: ok
// A file is the runtime's only under `rt/` or `out/gen/` of a With compiler
// checkout (the directory that holds seed.lock), or in the embedded copy.
// `/rt/` anywhere in the path used to be enough: in a folder named `rt`, a
// build.w could not call its own `with_*` helper at compile time ("has no
// With body to evaluate"), and a program could import `rt.*`. The #2613
// rule for `src/`, applied to the runtime.
// The test runs from the tree's root, which holds seed.lock.
use Resolve
use std.fs

fn main:
    assert(resolve_path_is_runtime("rt/rt_core.w"))
    assert(resolve_path_is_runtime("./rt/platform_posix.w"))
    assert(resolve_path_is_runtime("out/gen/rt_bundle_stage.w"))
    assert(resolve_path_is_runtime("<embedded-rt>/rt_core.w"))
    // A program in a folder named rt: no seed.lock beside the folder.
    let proj = "out/tmp/runtime_path_test/rt"
    assert(mkdir_p(proj ++ "/src") == 0)
    assert(not resolve_path_is_runtime(proj ++ "/build.w"))
    assert(not resolve_path_is_runtime(proj ++ "/src/main.w"))
    assert(not resolve_path_is_runtime("/nonexistent-rt-test/rt/main.w"))
    assert(not resolve_path_is_runtime("/nonexistent-rt-test/out/gen/main.w"))
    // A checkout kept in a folder named rt: only its own rt/ counts.
    let tree = "out/tmp/runtime_path_test/rt/with"
    assert(mkdir_p(tree ++ "/rt") == 0)
    assert(write_file(tree ++ "/seed.lock", "version=x\n") == 0)
    assert(resolve_path_is_runtime(tree ++ "/rt/rt_core.w"))
    assert(not resolve_path_is_runtime(tree ++ "/build.w"))
    assert(not resolve_path_is_runtime("art/x.w"))
    print("ok")
