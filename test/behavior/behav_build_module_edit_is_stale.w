//! expect-stdout: ok
// A module a program reaches through `use` is an input of its build. The
// build recorded only the entry file, C headers and embedded files, so an
// edit to any other module left the target "up to date": `with build` was
// green over a stale binary, and over a module that no longer compiled.
use std.fs
use pre_d_build_runner

fn main:
    let root = p7_prepare_case("module_edit_is_stale", "moduleedit")
    p7_write(root, "build.w",
        "use std.build\n\n" ++
        "pub fn build(ctx: BuildCtx) -> Build:\n" ++
        "    ctx.new_build().executable(\"moduleedit\", \"src/main.w\").default(\"moduleedit\")\n")
    p7_write(root, "src/helper.w", "pub fn answer -> i32: 41\n")
    p7_write(root, "src/main.w", "use helper\n\nfn main: print(f\"{answer()}\")\n")
    p7_assert_success(p7_run(root, "module-edit-first", p7_build_args()), "first build")
    let state: str = read_file(p7_join(root, "out/.build-state/moduleedit.state")) ?? ""
    assert(state.contains("src/helper.w:"))

    // Unchanged sources: the target is not rebuilt.
    let again = p7_run(root, "module-edit-again", p7_build_args())
    p7_assert_success(again, "unchanged build")
    assert(not again.stderr.contains("[time] moduleedit"))

    // An edit to the module rebuilds the program.
    p7_write(root, "src/helper.w", "pub fn answer -> i32: 1042\n")
    let rebuilt = p7_run(root, "module-edit-rebuilt", p7_build_args())
    p7_assert_success(rebuilt, "build after the module changed")
    assert(rebuilt.stderr.contains("[time] moduleedit"))

    // A module that no longer compiles fails the build.
    p7_write(root, "src/helper.w", "pub fn answer -> i32: nonsense(\n")
    assert(p7_run(root, "module-edit-broken", p7_build_args()).rc != 0)
    print("ok")
