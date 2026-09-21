//! skip-on: windows issue #800: action/capability/net/process/fs OS-surface fails on native Windows
//! expect-stdout: ok

use pre_d_build_runner
use std.fs
use std.process

// Early cutoff (D50; Go's content ID): a dependency that re-runs and leaves
// its declared outputs byte-identical has rebuilt nothing its dependents can
// see, so they stay fresh. `gen` copies the first line of its input to its
// output; `use` depends on it. Editing a later line of the input re-runs `gen`
// to the same bytes, and `use` must not run; editing the first line changes
// the output, and `use` must. WITH_BUILD_NO_EARLY_CUTOFF=1 restores "a
// dependency ran, so rebuild".
fn main:
    let case_dir = p7_prepare_case("build_early_cutoff", "earlycutoff")
    var build_text = "use std.build\n\n"
    build_text = build_text ++ "fn first_line(text: &str) -> str:\n"
    build_text = build_text ++ "    for i in 0..text.len():\n"
    build_text = build_text ++ "        if text[i] == '\\n': return text.slice(0, i)\n"
    build_text = build_text ++ "    text.clone()\n\n"
    build_text = build_text ++ "fn produce(ctx: ActionCtx) -> i32:\n"
    build_text = build_text ++ "    print(\"gen ran\")\n"
    build_text = build_text ++ "    ctx.fs().write_text(ctx.output(), first_line(ctx.fs().read_text(\"src/seed.txt\")))\n\n"
    build_text = build_text ++ "fn consume(ctx: ActionCtx) -> i32:\n"
    build_text = build_text ++ "    print(\"use ran\")\n"
    build_text = build_text ++ "    ctx.fs().write_text(ctx.output(), ctx.fs().read_text(\"out/gen/first.txt\") ++ \"!\")\n\n"
    build_text = build_text ++ "pub fn build(ctx: BuildCtx) -> Build:\n"
    build_text = build_text ++ "    var out = ctx.new_build()\n"
    build_text = build_text ++ "    var g = target_new(.Action, \"gen\", \"\").output(\"out/gen/first.txt\").input(\"src/seed.txt\")\n"
    build_text = build_text ++ "    g.action = produce\n"
    build_text = build_text ++ "    out = out.add_target(move g)\n"
    build_text = build_text ++ "    var u = target_new(.Action, \"use\", \"\").output(\"out/use/result.txt\").input(\"out/gen/first.txt\").dep(\"gen\")\n"
    build_text = build_text ++ "    u.action = consume\n"
    build_text = build_text ++ "    out = out.add_target(move u)\n"
    build_text = build_text ++ "    out.default(\"use\")\n"
    p7_write(case_dir, "build.w", build_text)

    p7_write(case_dir, "src/seed.txt", "alpha\nline two\n")
    let first = p7_run(case_dir, "cutoff-first", p7_build_args())
    p7_assert_success(first, "first build")
    assert(first.stdout.contains("gen ran") and first.stdout.contains("use ran"))
    assert(read_file(p7_join(case_dir, "out/use/result.txt")).unwrap() == "alpha!")

    // gen re-runs (its input changed) to the same bytes: use stays fresh.
    p7_write(case_dir, "src/seed.txt", "alpha\nline two, edited\n")
    let same = p7_run(case_dir, "cutoff-same-output", p7_build_args())
    p7_assert_success(same, "rebuild to identical output")
    assert(same.stdout.contains("gen ran"))
    assert(not same.stdout.contains("use ran"))
    assert(same.stderr.contains("[cutoff] 'gen' re-ran to identical outputs"))

    // gen's output changes: use runs.
    p7_write(case_dir, "src/seed.txt", "beta\nline two, edited\n")
    let changed = p7_run(case_dir, "cutoff-changed-output", p7_build_args())
    p7_assert_success(changed, "rebuild to a different output")
    assert(changed.stdout.contains("gen ran") and changed.stdout.contains("use ran"))
    assert(read_file(p7_join(case_dir, "out/use/result.txt")).unwrap() == "beta!")

    // The escape hatch: identical output, and use runs anyway.
    let previous = env("WITH_BUILD_NO_EARLY_CUTOFF").clone()
    assert(set_env("WITH_BUILD_NO_EARLY_CUTOFF", "1") == 0)
    p7_write(case_dir, "src/seed.txt", "beta\nline two, edited again\n")
    let forced = p7_run(case_dir, "cutoff-disabled", p7_build_args())
    assert(set_env("WITH_BUILD_NO_EARLY_CUTOFF", previous) == 0)
    p7_assert_success(forced, "rebuild with the cutoff off")
    assert(forced.stdout.contains("gen ran") and forced.stdout.contains("use ran"))
    print("ok")
