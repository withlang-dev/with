//! expect-stdout: ok
// #967: a manifest copy and a verified promotion check and read every entry
// before the first write. One entry at a time, a missing second input left
// the first destination already replaced: a mixed old/new tree on failure.
use pre_d_build_runner
use std.fs

fn main:
    let root = p7_prepare_case("manifest validates first", "manifest967")
    p7_write(root, "src/main.w", "fn main: print(1)\n")
    p7_write(root, "srcdir/a.txt", "replacement")
    p7_write(root, "dst/a.txt", "original")
    p7_write(root, "dst2/a.txt", "original")
    p7_write(root, "build.w", "use std.build\npub fn build(ctx: BuildCtx) -> Build:\n    let promote = target_new(.PromoteTreeIfVerified, \"promote\", \"srcdir\").output(\"dst\").input(\"a.txt\").input(\"b.txt\").dep(\"verify\")\n    let verify = target_new(.Group, \"verify\", \"\")\n    let copytree = target_new(.CopyTree, \"copy\", \"srcdir\").output(\"dst2\").input(\"a.txt\").input(\"b.txt\")\n    ctx.new_build().add_target(verify).add_target(promote).add_target(copytree).default(\"promote\")\n")
    for target in [":promote", ":copy"]:
        let result = p7_run(root, target, p7_build_target_args(target))
        p7_assert_failure_contains(&result, "missing input", target)
    let kept = read_file(p7_join(root, "dst/a.txt")) ?? "(gone)"
    let kept2 = read_file(p7_join(root, "dst2/a.txt")) ?? "(gone)"
    if kept != "original" or kept2 != "original":
        print(f"dst/a.txt [{kept}] dst2/a.txt [{kept2}]")
        assert(false)
    print("ok")
