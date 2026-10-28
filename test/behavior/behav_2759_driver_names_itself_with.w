//! expect-stdout: ok
// #2759/#2637: the compiler driving a build.w build names itself in WITH
// when the user did not, so an action resolving "the seed" gets the
// driver — never a different `with` found on PATH. On win10 an old
// PATH with.exe silently compiled the bootstrap bridges for a pinned
// seed driver and failed on `use rt.rt_core`.
use std.fs
use std.process
use pre_d_build_runner

fn main:
    let compiler = env("WITH_TEST_COMPILER")
    assert(compiler.len() > 0)
    let root = p7_prepare_case("driver_with", "driverwith")
    var build_text = "use std.build\n\n"
    build_text = build_text ++ "fn probe(ctx: ActionCtx) -> i32:\n"
    build_text = build_text ++ "    ctx.fs().write_text(\"out/driver.txt\", env(\"WITH\"))\n\n"
    build_text = build_text ++ "pub fn build(ctx: BuildCtx) -> Build:\n"
    build_text = build_text ++ "    var target = target_new(.Action, \"probe\", \"\").output(\"out/driver.txt\")\n"
    build_text = build_text ++ "    target.action = probe\n"
    build_text = build_text ++ "    target = target.write_scope(\"out\")\n"
    build_text = build_text ++ "    ctx.new_build().add_target(move target).default(\"probe\")\n"
    p7_write(root, "build.w", build_text)
    let previous = env("WITH")
    assert(set_env("WITH", "") == 0)
    let ran = p7_run(root, "driver-with", p7_build_args())
    assert(set_env("WITH", previous) == 0)
    p7_assert_success(ran, "driver names itself in WITH")
    let named: str = (read_file(p7_join(root, "out/driver.txt")) ?? "").trim()
    if named.len() == 0 or not file_exists(named):
        print(f"WITH named '{named}', which is not a file")
        exit_code(1)
    let base = p7_join(root, "versions")
    assert(mkdir_p(base) == 0)
    let v1 = run_to_files_in(root, &[compiler, "version"], p7_join(base, "driver.out"), p7_join(base, "driver.err"))
    let v2 = run_to_files_in(root, &[named, "version"], p7_join(base, "named.out"), p7_join(base, "named.err"))
    let driver_version: str = (read_file(p7_join(base, "driver.out")) ?? "").trim()
    let named_version: str = (read_file(p7_join(base, "named.out")) ?? "").trim()
    if v1.code != 0 or v2.code != 0 or named_version != driver_version:
        print(f"driver '{driver_version}' != named '{named_version}' ({named})")
        exit_code(1)
    print("ok")
