//! expect-stdout: ok

use BuildGraphModel
use BuildGraphSupport
use BuildGraphCache
use std.fs
use std.process

// A cached test verdict is keyed on the environment that changes what the
// compiler produces: `WITH_CODEGEN_UNITS=1 with test` was served the passes of
// runs without it (1367 of 1695 files in a D30 lane sweep), and a variable
// that shapes no compile leaves the key alone.
fn main:
    let graph = parse_build_graph("WITH_BUILD_GRAPH\t2\npackage\tordinary-app\t0.1.0\ndefault_target\tapp\ntarget\t0\tapp\tsrc/main.w\t0\t0\tout/app\n")
    assert(graph.ok)
    let target = &graph.targets[0]
    let test = "test/internals/test_verdict_key_env_test.w"
    let saved = env("WITH_CODEGEN_UNITS")
    assert(set_env("WITH_CODEGEN_UNITS", "") == 0)
    let plain = build_cache_test_verdict_key(".", target, "fp", "argv", test)
    assert(set_env("WITH_CODEGEN_UNITS", "2") == 0)
    let lane = build_cache_test_verdict_key(".", target, "fp", "argv", test)
    assert(set_env("WITH_CODEGEN_UNITS", saved) == 0)
    assert(plain != lane)
    let saved_jobs = env("WITH_BUILD_JOBS")
    assert(set_env("WITH_BUILD_JOBS", "3") == 0)
    let with_jobs = build_cache_test_verdict_key(".", target, "fp", "argv", test)
    assert(set_env("WITH_BUILD_JOBS", saved_jobs) == 0)
    assert(with_jobs == build_cache_test_verdict_key(".", target, "fp", "argv", test))
    print("ok")
