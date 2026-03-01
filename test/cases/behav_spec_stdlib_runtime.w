//! expect-stdout: ok

// Spec conformance: runtime, stdlib, and CLI surface
// Tracks docs/missing_features2.md section 5 (items 38-42)

use spec_harness

extern fn with_system(cmd: str) -> i32

fn test_38_fiber_runtime_linked_by_default() -> i32:
    let src = "async fn one() -> i32:\n    1\nfn main:\n    let t = spawn one()\n    let v = await t\n    assert(v == 1)\n    println(\"ok\")\n"
    let rc = run_run_case("spec_runtime_38_fiber", src)
    expect_eq_i32(rc, CR_OK(), "38 async/fiber runtime works by default")

fn test_39_std_sync_real_primitives() -> i32:
    let src = "use sync\nfn main:\n    let m = Mutex[i32].new(0)\n    with m.lock() as g:\n        g.write(7)\n    with m.lock() as g2:\n        assert(g2.read() == 7)\n    println(\"ok\")\n"
    let rc = run_run_case("spec_runtime_39_sync", src)
    expect_eq_i32(rc, CR_OK(), "39 std.sync provides real generic primitives")

fn test_40_spawn_os_is_asynchronous() -> i32:
    let src = "use thread\nvar touched = 0\nfn worker() -> i32:\n    touched = 1\n    7\nfn main:\n    let h = spawn_os(worker)\n    assert(touched == 0)\n    let v = join(h)\n    assert(v == 7)\n    assert(touched == 1)\n    println(\"ok\")\n"
    let rc = run_run_case("spec_runtime_40_spawn_os", src)
    expect_eq_i32(rc, CR_OK(), "40 std.thread.spawn_os runs asynchronously")

fn test_41_option_result_wrappers_are_generic() -> i32:
    let src = "use option\nuse result\nfn up(s: str) -> str:\n    s ++ \"!\"\nfn main:\n    let a: ?str = \"hi\"\n    let b = map(a, up)\n    assert(b.unwrap_or(\"\") == \"hi!\")\n    let r: Result[str, i32] = Ok(\"ok\")\n    let r2 = result.map(r, up)\n    assert(r2.unwrap_or(\"\") == \"ok!\")\n    println(\"ok\")\n"
    let rc = run_run_case("spec_runtime_41_generic_wrappers", src)
    expect_eq_i32(rc, CR_OK(), "41 std.option/std.result wrappers are generic")

fn test_42_cli_surface_commands_present() -> i32:
    var failures = 0
    failures = failures + expect_eq_i32(with_system("./with test --help > /dev/null 2>&1"), 0, "42 cli has `with test`")
    failures = failures + expect_eq_i32(with_system("./with fmt --help > /dev/null 2>&1"), 0, "42 cli has `with fmt`")
    failures = failures + expect_eq_i32(with_system("./with doc --help > /dev/null 2>&1"), 0, "42 cli has `with doc`")
    failures = failures + expect_eq_i32(with_system("./with repl --help > /dev/null 2>&1"), 0, "42 cli has `with repl`")
    failures

fn main:
    var failures = 0
    failures = failures + test_38_fiber_runtime_linked_by_default()
    failures = failures + test_39_std_sync_real_primitives()
    failures = failures + test_40_spawn_os_is_asynchronous()
    failures = failures + test_41_option_result_wrappers_are_generic()
    failures = failures + test_42_cli_surface_commands_present()
    finalize_failures(failures)
