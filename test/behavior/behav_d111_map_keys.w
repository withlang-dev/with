//! expect-stdout: ok

// D110 (a probe key is observed; an inserted key is the map's own copy) and
// D111 (a str key is a value): the case file uses a key after every map and
// set operation. Under the debug allocator, with freed memory scribbled and
// with and without block reuse, the key reads its original text and nothing
// leaks or is freed twice.

use pre_d_build_runner
use std.fs
use std.process

fn main:
    let previous_reuse = env("WITH_ALLOC_NO_REUSE")
    let previous_scribble = env("WITH_DEBUG_ALLOC_SCRIBBLE")
    assert(set_env("WITH_DEBUG_ALLOC_SCRIBBLE", "1") == 0)
    let root = p7_prepare_case("d111_map_keys", "d111mapkeys")
    p7_write(root, "src/main.w", read_file(p7_abs("test/behavior/lib/map_key_cases.w")).unwrap())
    for no_reuse in ["", "1"]:
        assert(set_env("WITH_ALLOC_NO_REUSE", no_reuse) == 0)
        let label = "d111_map_keys" ++ (if no_reuse == "1": " (no reuse)" else: "")
        let result = p7_run(root, label, "run\0--debug-alloc\0src/main.w\0")
        p7_assert_success(result, label)
        if not result.stderr.contains("debug-alloc: leak count=0"):
            eprint(label ++ ": " ++ result.stderr)
            assert(false)
        assert(not result.stderr.contains("DOUBLE FREE"))
        assert(result.stdout.contains("ok"))
    assert(set_env("WITH_ALLOC_NO_REUSE", previous_reuse) == 0)
    assert(set_env("WITH_DEBUG_ALLOC_SCRIBBLE", previous_scribble) == 0)
    print("ok")
