module build.examples

// The examples lane (#1150, D55 ruling 4): every program under examples/
// is built with the release compiler and run, and every package test
// runs, so a rotted example turns the battery red. The list is the
// lane's contract: untracked user work beside it (examples/spiral) is not
// an example. Nothing is written under examples/: binaries land under the
// lane's output directory and the tests run from the project root.

use std.build
use std.sysinfo

fn ex_join(left: &str, right: &str) -> str:
    if left.ends_with("/"): left ++ right else: left ++ "/" ++ right

fn ex_abs(root: &str, path: &str) -> str:
    if path.len() > 0 and path[0] == '/': return path.clone()
    ex_join(root, path)

/// The diagnostic lines of a compiler's stderr, without the warning flood.
fn ex_error_lines(text: &str) -> str:
    var out = ""
    for line in text.split("\n"):
        if line.starts_with("error") or line.starts_with(" -->") or line.starts_with("panic"):
            out = out ++ line ++ "\n"
    out

fn ex_slug(path: &str) -> str:
    path.replace("/", "_").replace(".w", "")

/// Single-file examples: built with `with build`, then run from their
/// directory.
fn ex_programs() -> List[str]:
    var out = List.new()
    out.push("examples/hello.w")
    out.push("examples/fizzbuzz.w")
    out.push("examples/json_test.w")
    out.push("examples/async-auction.w")
    out.push("examples/async-collection-await.w")
    out.push("examples/async-tuple-await.w")
    out.push("examples/idiomatic/idiomatic.w")
    out.push("examples/channels/pipeline.w")
    out.push("examples/ephemerality-and-lowering/ephemerality_and_lowering.w")
    out.push("examples/json-parser/json.w")
    out

/// Packages (a `with.toml` and `src/main.w`): built from their entry,
/// then run from the package directory.
fn ex_packages() -> List[str]:
    var out = List.new()
    out.push("examples/ecs")
    out.push("examples/nebula")
    out.push("examples/service")
    out

/// Projects with a build.w of their own: `with run`, then their `test`
/// target, from the project directory, as their README says to. They were
/// in no lane, and examples/c-interop's tests failed on main unseen (#2137).
/// It reads the host's sqlite3.h, which a Windows host does not have.
fn ex_projects() -> List[str]:
    var out = List.new()
    if os() != "Windows": out.push("examples/c-interop")
    out

/// Package test files (standalone), run with `with test` from the root.
fn ex_tests() -> List[str]:
    var out = List.new()
    out.push("examples/channels/test/pipeline_test.w")
    out.push("examples/ecs/test/ecs_test.w")
    out.push("examples/ephemerality-and-lowering/test/ephemerality_and_lowering_test.w")
    out.push("examples/json-parser/test/json_test.w")
    out.push("examples/nebula/test/nebula_test.w")
    out.push("examples/service/test/service_test.w")
    out

/// Files checked only: a benchmark has no main.
fn ex_checked() -> List[str]:
    var out = List.new()
    out.push("examples/bench_demo.w")
    out

fn ex_dirname(path: &str) -> str:
    var last_slash: i64 = -1
    for i in 0..path.len():
        if path[i] == '/': last_slash = i
    path.slice(0, last_slash)

/// A facade an example carries as its own copy of the toolchain's (spec
/// §16.2b.1: a facade is the importing project's; ruling §66): the example
/// demonstrates the mechanism, not divergence, so the copy is the toolchain's
/// file byte for byte below a marker line that closes the example's own
/// header. The check is what keeps the header's "diff clean" claim true; a
/// copy that drifted (examples/c-interop missed Amendment 1 until D76) taught
/// a stale contract.
fn ex_facade_copies() -> List[str]:
    var out = List.new()
    out.push("examples/c-interop/src/facades/sqlite3.w")
    out

/// The toolchain file a copy is taken from.
fn ex_facade_original(path: &str) -> str:
    if path == "examples/c-interop/src/facades/sqlite3.w": return "lib/facades/sqlite3.w"
    ""

fn ex_facade_marker() -> str: "// ── verbatim: "

/// The copy's text below its marker line, or "" when it has none.
fn ex_below_marker(text: &str) -> str:
    let marker = ex_facade_marker()
    var start = 0
    while start < text.len() as i32:
        var end = start
        while end < text.len() as i32 and text[end] != '\n': end = end + 1
        if text.slice(start, end).starts_with(marker):
            return if end < text.len() as i32: text.slice(end + 1, text.len()) else: ""
        start = end + 1
    ""

/// One verdict per copy that is not the toolchain's file byte for byte.
fn ex_facade_copy_failures(ctx: &ActionCtx) -> i32:
    var failures = 0
    let fs = ctx.fs()
    for path in ex_facade_copies():
        let original = ex_facade_original(path)
        let text = fs.read_text(path)
        let below = ex_below_marker(text)
        if below.len() == 0:
            print(f"examples-tests: {path} has no `{ex_facade_marker()}<path>` marker line closing its header; the toolchain's facade follows that line verbatim")
            failures += 1
        else if below != fs.read_text(original):
            print(f"examples-tests: {path} differs from {original} below its marker line; the example's copy of the toolchain's facade is byte-identical (a project's own facade may diverge, an example's copy teaches the current contract) — refresh it: keep the header through the marker, then the toolchain's file verbatim")
            failures += 1
    failures

/// Runs one lane step; a failure is printed (with the compiler's
/// diagnostic lines) and counted, never fatal on its own, so one run
/// reports every rotted example.
fn ex_run(ctx: &ActionCtx, args: List[str], label: &str, cwd: &str, timeout_ms: i32) -> i32:
    let root = ctx.project_info().project_root()
    let out_dir = ctx.output()
    let stdout_rel = ex_join(out_dir, label ++ ".stdout")
    let stderr_rel = ex_join(out_dir, label ++ ".stderr")
    let result = ctx.process_runner().run_capture_cwd(args, ex_abs(root, stdout_rel), ex_abs(root, stderr_rel), timeout_ms, cwd)
    if result.rc != 0:
        let stderr = ctx.fs().read_text(stderr_rel)
        let detail = ex_error_lines(stderr)
        print(f"examples-tests: {label} failed with exit code {result.rc}")
        if detail.len() > 0: print(detail) else: print(stderr)
        return 1
    0

pub fn run_examples_tests_action(ctx: ActionCtx) -> i32:
    let inputs = ctx.inputs()
    if inputs.len() == 0:
        ctx.diagnostics().error("examples-tests: missing compiler input")
    let fs = ctx.fs()
    let out_dir = ctx.output()
    if out_dir.len() == 0:
        ctx.diagnostics().error("examples-tests: missing output directory")
    if fs.exists(out_dir) and fs.remove_tree(out_dir) != 0:
        ctx.diagnostics().error("examples-tests: could not remove previous output directory: " ++ out_dir)
    if fs.mkdir_all(out_dir) != 0:
        ctx.diagnostics().error("examples-tests: could not create output directory: " ++ out_dir)
    let root = ctx.project_info().project_root()
    if not fs.exists(inputs[0]):
        ctx.diagnostics().error("examples-tests: missing compiler: " ++ inputs[0])
    let compiler = ex_abs(root, inputs[0])
    var failures = ex_facade_copy_failures(ctx)

    for source in ex_checked():
        var args: List[str] = List.new()
        args.push(compiler.clone())
        args.push("check")
        args.push(ex_abs(root, source))
        failures += ex_run(ctx, args, ex_slug(source) ++ ".check", root, 120000)

    for source in ex_programs():
        let slug = ex_slug(source)
        let binary = ex_abs(root, ex_join(out_dir, slug))
        var build_args: List[str] = List.new()
        build_args.push(compiler.clone())
        build_args.push("build")
        build_args.push(ex_abs(root, source))
        build_args.push("-o")
        build_args.push(binary.clone())
        if ex_run(ctx, build_args, slug ++ ".build", root, 300000) != 0:
            failures += 1
            continue
        var run_args: List[str] = List.new()
        run_args.push(binary.clone())
        failures += ex_run(ctx, run_args, slug ++ ".run", ex_abs(root, ex_dirname(source)), 60000)

    for package in ex_packages():
        let slug = ex_slug(package)
        let binary = ex_abs(root, ex_join(out_dir, slug))
        var build_args: List[str] = List.new()
        build_args.push(compiler.clone())
        build_args.push("build")
        build_args.push(ex_abs(root, ex_join(package, "src/main.w")))
        build_args.push("-o")
        build_args.push(binary.clone())
        if ex_run(ctx, build_args, slug ++ ".build", root, 300000) != 0:
            failures += 1
            continue
        var run_args: List[str] = List.new()
        run_args.push(binary.clone())
        failures += ex_run(ctx, run_args, slug ++ ".run", ex_abs(root, package), 60000)

    for project in ex_projects():
        let slug = ex_slug(project)
        var run_args: List[str] = List.new()
        run_args.push(compiler.clone())
        run_args.push("run")
        failures += ex_run(ctx, run_args, slug ++ ".run", ex_abs(root, project), 300000)
        var test_args: List[str] = List.new()
        test_args.push(compiler.clone())
        test_args.push("build")
        test_args.push(":test")
        failures += ex_run(ctx, test_args, slug ++ ".test", ex_abs(root, project), 300000)

    for test in ex_tests():
        var args: List[str] = List.new()
        args.push(compiler.clone())
        args.push("test")
        args.push(ex_abs(root, test))
        failures += ex_run(ctx, args, ex_slug(test), root, 300000)

    if failures > 0:
        ctx.diagnostics().error(f"examples-tests: {failures} step(s) failed; an example tracks the current spec (D55 ruling 4): a spec change updates it in the same change, a compiler or stdlib change that breaks it is a defect")
    let total = ex_checked().len() + ex_programs().len() + ex_packages().len() + ex_projects().len() * 2 + ex_tests().len()
    let _ = fs.write_text(ex_join(out_dir, ".stamp"), f"ok: {total} example steps\n")
    print(f"examples-tests: {total} steps green")
    0
