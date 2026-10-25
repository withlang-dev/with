//! expect-stdout: ok
// #2613: a file is the compiler's own source only when it sits under the
// `src/` of a With compiler checkout (the directory that holds seed.lock).
// Any other `src` in the path is not one: a user project's src/main.w used
// to pass the runtime boundary (`use rt.rt_core` was accepted), and a
// checkout kept under ~/src judged its tools/ files compiler source.
// The test runs from the tree's root, which holds seed.lock.
use Resolve
use std.fs

fn main:
    assert(resolve_path_is_compiler_source("src/main.w"))
    assert(resolve_path_is_compiler_source("src/compiler/Link.w"))
    assert(resolve_path_is_compiler_source("./src/Resolve.w"))
    // A user project: its src/ has no seed.lock beside it.
    let proj = "out/tmp/compiler_source_path_test/proj"
    assert(mkdir_p(proj ++ "/src") == 0)
    assert(not resolve_path_is_compiler_source(proj ++ "/src/main.w"))
    // A checkout kept under a directory named src: only its own src/ counts.
    let tree = "out/tmp/compiler_source_path_test/src/with"
    assert(mkdir_p(tree ++ "/src") == 0)
    assert(mkdir_p(tree ++ "/tools") == 0)
    assert(write_file(tree ++ "/seed.lock", "version=x\n") == 0)
    assert(not resolve_path_is_compiler_source(tree ++ "/tools/with-sha256.w"))
    assert(resolve_path_is_compiler_source(tree ++ "/src/main.w"))
    assert(not resolve_path_is_compiler_source("/nonexistent-2613/src/with/tools/with-sha256.w"))
    assert(not resolve_path_is_compiler_source("<embedded-std>/std/string.w"))
    print("ok")
