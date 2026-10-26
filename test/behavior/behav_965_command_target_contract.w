//! expect-stdout: ok
//! skip-on: windows the children are /usr/bin/env, /bin/pwd, /bin/sleep and /usr/bin/true
// #965: a command target runs its child as it declares: with its environment
// (`with_env`), in its working directory (`working_dir`), under its timeout,
// and it fails when an extra output it declares is not there. All four were
// dropped: the parent's environment, the project root, 300 s, a green build.
use pre_d_build_runner
use std.fs

fn main:
    let root = p7_prepare_case("command contract", "cmd965")
    p7_write(root, "src/main.w", "fn main: print(1)\n")
    p7_write(root, "sub/keep.txt", "x")
    var build_text = "use std.build\npub fn build(ctx: BuildCtx) -> Build:\n"
    build_text = build_text ++ "    let envt = target_new(.Command, \"envt\", \"/usr/bin/env\").with_env(\"TRIAGE_965\", \"set\")\n"
    build_text = build_text ++ "    let pwdt = target_new(.Command, \"pwdt\", \"/bin/pwd\").working_dir(\"sub\")\n"
    build_text = build_text ++ "    let slow = target_new(.Command, \"slow\", \"/bin/sleep\").arg(\"5\").timeout(300)\n"
    build_text = build_text ++ "    let extra = target_new(.Command, \"extra\", \"/usr/bin/true\").extra_output(\"never-made.txt\")\n"
    build_text = build_text ++ "    ctx.new_build().add_target(envt).add_target(pwdt).add_target(slow).add_target(extra).default(\"envt\")\n"
    p7_write(root, "build.w", build_text)
    p7_assert_success(&p7_run(root, ":envt", p7_build_target_args(":envt")), ":envt")
    p7_assert_file_contains(root, "out/command/envt/stdout.txt", "TRIAGE_965=set")
    p7_assert_success(&p7_run(root, ":pwdt", p7_build_target_args(":pwdt")), ":pwdt")
    p7_assert_file_contains(root, "out/command/pwdt/stdout.txt", "/sub\n")
    p7_assert_failure_contains(&p7_run(root, ":slow", p7_build_target_args(":slow")), "timed out after 300ms", ":slow")
    p7_assert_failure_contains(&p7_run(root, ":extra", p7_build_target_args(":extra")), "did not produce declared extra output", ":extra")
    print("ok")
