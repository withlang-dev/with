//! expect-stdout: ok
// #1041 (§10.2, §18.5c): `??` on an Option evaluates in a build.w, as `match`
// on one does. The build evaluator sent the `??` node to its integer
// operators: "operator requires integer comptime values".
use pre_d_build_runner

fn main:
    let root = p7_prepare_case("option default", "optdefault")
    p7_write(root, "src/main.w", "fn main: print(1)\n")
    var build_text = "use std.build\npub fn build(ctx: BuildCtx) -> Build:\n"
    build_text = build_text ++ "    var v: List[i32] = List.new()\n"
    build_text = build_text ++ "    let none = v.pop() ?? 7\n"
    build_text = build_text ++ "    v.push(3)\n"
    build_text = build_text ++ "    let some = v.pop() ?? 7\n"
    build_text = build_text ++ "    assert(none == 7 and some == 3)\n"
    build_text = build_text ++ "    ctx.new_build().executable(\"app\", \"src/main.w\")\n"
    p7_write(root, "build.w", build_text)
    let graph = p7_run(root, "option-default-graph", p7_build_graph_args())
    p7_assert_success(graph, "build.w with ?? on an Option")
    print("ok")
