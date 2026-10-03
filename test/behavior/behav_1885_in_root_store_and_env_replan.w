//! expect-stdout: ok

// #1885: an install destination spelled as an absolute path inside the
// project is contained in it, not an escape (`WITH_WO_DIR=<root>/out/with-wo`
// was refused as "escapes project root"); and when the variable that named
// it goes away, the graph re-plans from the environment as it is now, not
// the cached one. An absolute path outside the project is still refused.
use pre_d_build_runner
use std.fs
use std.process

fn main:
    let case_dir = p7_prepare_case("build_1885_in_root_store", "inrootstore")
    var build_text = "use std.build\n\n"
    build_text = build_text ++ "pub fn build(ctx: BuildCtx) -> Build:\n"
    build_text = build_text ++ "    var out = ctx.new_build()\n"
    build_text = build_text ++ "    let store = ctx.env_input(\"BEHAV_1885_STORE\")\n"
    build_text = build_text ++ "    let dest_dir = if store.len() > 0: store else: \"out/default-store\"\n"
    build_text = build_text ++ "    out = out.install(\"put\", \"src/payload.txt\", dest_dir ++ \"/payload.txt\")\n"
    build_text = build_text ++ "    out.default(\"put\")\n"
    p7_write(case_dir, "build.w", build_text)
    p7_write(case_dir, "src/payload.txt", "payload\n")

    // An absolute store beneath the project root.
    let abs_store = p7_abs(p7_join(case_dir, "out/abs-store"))
    assert(set_env("BEHAV_1885_STORE", abs_store) == 0)
    let in_root = p7_run(case_dir, "1885-in-root", p7_build_args())
    p7_assert_success(in_root, "absolute store inside the project")
    assert(read_file(abs_store ++ "/payload.txt").unwrap() == "payload\n")

    // The variable removed: the plan follows the environment of this run.
    assert(set_env("BEHAV_1885_STORE", "") == 0)
    let unset = p7_run(case_dir, "1885-unset", p7_build_args())
    p7_assert_success(unset, "store variable removed")
    assert(read_file(p7_join(case_dir, "out/default-store/payload.txt")).unwrap() == "payload\n")

    // An absolute store outside the project is an escape.
    let outside = p7_abs(p7_join(p7_dirname(case_dir), "outside-store-1885"))
    assert(set_env("BEHAV_1885_STORE", outside) == 0)
    let escaped = p7_run(case_dir, "1885-outside", p7_build_args())
    p7_assert_failure_contains(escaped, "escapes project root", "absolute store outside the project")
    assert(not file_exists(outside ++ "/payload.txt"))
    assert(set_env("BEHAV_1885_STORE", "") == 0)
    print("ok")
