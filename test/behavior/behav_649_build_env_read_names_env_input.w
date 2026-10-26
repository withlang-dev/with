//! expect-stdout: ok

use pre_d_build_runner

// #649 (§17.1a): a build file reads the environment as a declared input.
// Both raw spellings are refused at comptime, and the refusal names
// `ctx.env_input` instead of only saying what is not allowed; the declared
// read builds.
fn build_file(read: str) -> str:
    "use std.build\nuse std.process\n\ncomptime with BuildCtx as ctx:\npub fn build -> Build:\n    let home = " ++ read ++ "\n    var out = ctx.new_build().executable(\"app\", \"src/main.w\")\n    if home.len() == 0: out = out.default(\"none\")\n    out\n"

fn main:
    let case_dir = p7_prepare_case("env_input_named", "envinputnamed")
    p7_write(case_dir, "src/main.w", "fn main:\n    print(1)\n")
    p7_write(case_dir, "build.w", build_file("env(\"HOME\")"))
    p7_assert_failure_contains(p7_run(case_dir, "env-call", "build\0"), "ctx.env_input(\"NAME\")", "env() in a build file")
    p7_write(case_dir, "build.w", build_file("unsafe { with_getenv_str(\"HOME\") }"))
    p7_assert_failure_contains(p7_run(case_dir, "raw-getenv", "build\0"), "ctx.env_input(\"NAME\")", "raw getenv in a build file")
    p7_write(case_dir, "build.w", build_file("ctx.env_input(\"HOME\")"))
    p7_assert_success(p7_run(case_dir, "env-input", "build\0"), "ctx.env_input in a build file")
    print("ok")
