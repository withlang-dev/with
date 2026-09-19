//! expect-stdout: ok

// D44 / §2.3 (#1158, #1187): map traversal and map snapshots never make a
// second owner. A plain run passed while the map was being corrupted, so
// both case files run under the debug allocator with freed memory scribbled,
// once with block reuse and once without, and must report zero leaks.

use pre_d_build_runner
use std.fs
use std.process

fn run_cases(case_name: &str, package: &str, source: &str):
    let root = p7_prepare_case(case_name, package)
    p7_write(root, "src/main.w", read_file(p7_abs(source)).unwrap())
    for no_reuse in ["", "1"]:
        assert(set_env("WITH_ALLOC_NO_REUSE", no_reuse) == 0)
        let label = case_name ++ (if no_reuse == "1": " (no reuse)" else: "")
        let result = p7_run(root, label, "run\0--debug-alloc\0src/main.w\0")
        p7_assert_success(result, label)
        if not result.stderr.contains("debug-alloc: leak count=0"):
            eprint(label ++ ": " ++ result.stderr)
            assert(false)
        assert(not result.stderr.contains("DOUBLE FREE"))
        assert(not result.stderr.contains("ledger full"))

fn main:
    let previous_reuse = env("WITH_ALLOC_NO_REUSE").clone()
    let previous_scribble = env("WITH_DEBUG_ALLOC_SCRIBBLE").clone()
    assert(set_env("WITH_DEBUG_ALLOC_SCRIBBLE", "1") == 0)
    run_cases("d44_map_traversal", "d44maptraversal", "test/behavior/lib/map_traversal_cases.w")
    run_cases("d44_map_snapshots", "d44mapsnapshots", "test/behavior/lib/map_snapshot_cases.w")
    run_cases("d44_map_remove", "d44mapremove", "test/behavior/lib/map_remove_cases.w")
    assert(set_env("WITH_ALLOC_NO_REUSE", previous_reuse) == 0)
    assert(set_env("WITH_DEBUG_ALLOC_SCRIBBLE", previous_scribble) == 0)
    print("ok")
