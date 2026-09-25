//! expect-stdout: ok

use pre_d_build_runner
use std.fs

fn rss_build_source(budget: &str):
    "use std.build\nfn write_output(ctx: ActionCtx) -> i32:\n    if ctx.target_name() == \"owner\":\n        assert(ctx.args().len() == 1)\n        assert(ctx.args()[0] == \"visible\")\n    ctx.fs().write_text(ctx.output(), \"ok\")\npub fn build(ctx: BuildCtx) -> Build:\n    var owner = target_new(.Action, \"owner\", \"\").output(\"out/owner\").arg(\"visible\").allow_parallel()" ++ budget ++ "\n    owner.action = write_output\n    var consumer = target_new(.Action, \"consumer\", \"\").output(\"out/consumer\").dep(\"owner\")\n    consumer.action = write_output\n    ctx.new_build().add_target(owner).add_target(consumer).default(\"consumer\")\n"

fn main:
    let dir = p7_prepare_case("build_rss_budget", "rss_budget")
    p7_write(dir, "build.w", rss_build_source(""))
    p7_assert_success(p7_run(dir, "rss_unbudgeted", "build\0"), "ordinary project has no implicit budget")
    p7_write(dir, "build.w", rss_build_source(".rss_limit(1073741824)"))
    p7_assert_success(p7_run(dir, "rss_configured", "build\0"), "explicit compiler-sized budget")
    // Changing only the budget must invalidate the previously successful
    // target. Failure must block its dependent and remain a failure on retry.
    assert(remove_file(p7_join(dir, "out/consumer")) == 0)
    p7_write(dir, "build.w", rss_build_source(".rss_limit(1)"))
    for label in ["rss_too_small", "rss_too_small_again"]:
        let result = p7_run(dir, label, "build\0")
        p7_assert_failure_contains(result, "rss tripwire: target 'owner'", label)
        assert(result.stderr.contains("limit 1 bytes"))
        assert(not file_exists(p7_join(dir, "out/consumer")))
    p7_write(dir, "build.w", rss_build_source(".rss_limit(0)"))
    p7_assert_failure_contains(p7_run(dir, "rss_invalid", "build\0"), "positive i64 byte count", "invalid budget")
    print("ok")
