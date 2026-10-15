//! expect-stdout: ok

// A panic site names the module's canonical path (D38/D50): under
// WITH_FILE_PREFIX_MAP the mapped one, never the checkout's absolute path.
// Every bundle and stage built from a worktree carried that worktree's path
// in each unwrap message, so identical sources gave a different compiler in
// every worktree and the machine-wide stores served one worktree's paths to
// the others (2026-10-14).
use pre_d_build_runner
use std.fs
use std.process

fn main:
    let case_dir = p7_prepare_case("panic_path_canonical", "panicpath")
    p7_write(case_dir, "src/main.w", "fn main:\n    let v: Option[i32] = None\n    print(f\"{v.unwrap()}\")\n")
    // The source is named by its absolute path, as the stage and bundle
    // builds name theirs; a relative spelling stays as spelled.
    assert(set_env("WITH_FILE_PREFIX_MAP", case_dir ++ "=/mapped") == 0)
    let run = p7_run(case_dir, "emit-obj under a prefix map", "build\0" ++ case_dir ++ "/src/main.w\0--emit-obj\0-o\0out/main.o\0")
    assert(set_env("WITH_FILE_PREFIX_MAP", "") == 0)
    if run.rc != 0:
        eprint(run.stderr)
        assert(false)
    let obj = read_file(case_dir ++ "/out/main.o") ?? ""
    assert(obj.len() > 0)
    assert(obj.contains("/mapped/src/main.w:3:"))
    assert(not obj.contains(case_dir ++ "/src/main.w"))
    print("ok")
