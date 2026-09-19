//! expect-stdout: ok

// §2.3, §13 (#1197): `for` over a slice or array never makes a second owner and
// never consumes the sequence. A plain run passed while the array's strings
// were being freed, so the cases run under the debug allocator with freed
// memory scribbled, once with block reuse and once without, with zero leaks.

use pre_d_build_runner
use std.fs
use std.process

fn main:
    let previous_reuse = env("WITH_ALLOC_NO_REUSE").clone()
    let previous_scribble = env("WITH_DEBUG_ALLOC_SCRIBBLE").clone()
    assert(set_env("WITH_DEBUG_ALLOC_SCRIBBLE", "1") == 0)
    let root = p7_prepare_case("sequence_traversal_observes", "seqtraversal")
    p7_write(root, "src/main.w", read_file(p7_abs("test/behavior/lib/sequence_traversal_cases.w")).unwrap())
    for no_reuse in ["", "1"]:
        assert(set_env("WITH_ALLOC_NO_REUSE", no_reuse) == 0)
        let label = "sequence traversal" ++ (if no_reuse == "1": " (no reuse)" else: "")
        let result = p7_run(root, label, "run\0--debug-alloc\0src/main.w\0")
        p7_assert_success(result, label)
        if not result.stderr.contains("debug-alloc: leak count=0"):
            eprint(label ++ ": " ++ result.stderr)
            assert(false)
        assert(not result.stderr.contains("DOUBLE FREE"))
    assert(set_env("WITH_ALLOC_NO_REUSE", previous_reuse) == 0)
    assert(set_env("WITH_DEBUG_ALLOC_SCRIBBLE", previous_scribble) == 0)
    print("ok")
