//! expect-stdout: ok

use pre_d_build_runner

fn main:
    let case_dir = p7_prepare_case("basic_invocation", "p7basic")
    var build_text = "use std.build\n\n"
    build_text = build_text ++ "pub fn build(ctx: BuildCtx) -> Build:\n"
    build_text = build_text ++ "    ctx.diagnostics().warn(\"basic build invoked\")\n"
    build_text = build_text ++ "    var target = target_new(.Executable, \"demo\", \"src/main.w\")\n"
    build_text = build_text ++ "    target = target.define(\"P7_BASIC=1\")\n"
    build_text = build_text ++ "    target = target.link_system_lib(\"m\")\n"
    build_text = build_text ++ "    var out = ctx.new_build()\n"
    build_text = build_text ++ "    out = out.add_target(target)\n"
    build_text = build_text ++ "    out.default(\"demo\")\n"
    p7_write(case_dir, "build.w", build_text)
    let result = p7_run(case_dir, "basic-invocation", p7_build_graph_args())
    p7_assert_success(result, "basic invocation")
    assert(result.stdout.contains("WITH_BUILD_GRAPH\t2"))
    assert(result.stdout.contains("target\t0\tdemo\tsrc/main.w"))
    assert(result.stdout.contains("define\t0\tP7_BASIC=1"))
    assert(result.stdout.contains("system_lib\t0\tm"))
    assert(result.stderr.contains("basic build invoked"))
    print("ok")
