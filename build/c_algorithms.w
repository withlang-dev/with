module build.c_algorithms

use std.build

const CALG_REVISION = "23d453792ed89a28ed7d2c8d4311a4d9f7822edd"
const CALG_SHA256 = "c2e9f3ba13d5373f79a70fa27d93730de98af314f2476190b156eee2a638a51b"

fn calg_modules() -> Vec[str]:
    ["arraylist", "avl-tree", "binary-heap", "binomial-heap", "bloom-filter",
     "compare-int", "compare-pointer", "compare-string", "hash-int",
     "hash-pointer", "hash-string", "hash-table", "list", "queue", "rb-tree",
     "set", "slist", "sortedarray", "trie"]

fn calg_tests() -> Vec[str]:
    ["alloc-testing", "arraylist", "avl-tree", "binary-heap", "binomial-heap",
     "bloom-filter", "cpp", "list", "slist", "queue", "compare-functions",
     "hash-functions", "hash-table", "rb-tree", "set", "trie", "sortedarray"]

// Upstream's test framework and its smoke program (test-cpp exercises every
// module once) ride along in the production corpus as the wo-drift harness;
// they are never part of the bundle root.
fn calg_is_harness(name: &str) -> bool:
    for harness in ["alloc_testing", "framework", "test_cpp"]:
        if name == harness: return true
    false

fn calg_fail(ctx: &ActionCtx, message: &str):
    ctx.diagnostics().error(ctx.target_name() ++ ": " ++ message)
    1

fn calg_abs(ctx: &ActionCtx, path: &str): ctx.project_info().project_root() ++ "/" ++ path
fn calg_scratch(ctx: &ActionCtx): "out/tmp/action-scratch/" ++ ctx.target_name()

fn calg_basename(path: &str) -> str:
    let parts = path.split("/")
    parts[parts.len() - 1].clone()

fn calg_module_name(path: &str) -> str:
    let base = calg_basename(path)
    for i in 0..base.len():
        if base[i] == '.': return base.slice(0, i)
    base

fn calg_reset(ctx: &ActionCtx, path: &str):
    let fs = ctx.fs()
    if fs.exists(path) and fs.remove_tree(path) != 0:
        return calg_fail(ctx, "cannot remove " ++ path)
    if fs.mkdir_all(path) != 0: return calg_fail(ctx, "cannot create " ++ path)
    0

fn calg_copy(ctx: &ActionCtx, source: &str, destination: &str):
    if ctx.fs().copy_file(source, destination) != 0:
        return calg_fail(ctx, "cannot copy " ++ source ++ " to " ++ destination)
    0

fn calg_copy_test_sources(ctx: &ActionCtx, reference: &str, source: &str):
    for name in ["alloc-testing", "framework"]:
        for extension in [".c", ".h"]:
            if calg_copy(ctx, reference ++ "/test/" ++ name ++ extension, source ++ "/" ++ name ++ extension) != 0: return 1
    0

fn calg_options(source: &str, output: &str, testing: bool) -> MigrateOptions:
    MigrateOptions {
        source_path: source.clone(), output_path: output.clone(),
        include_paths: [source.clone()], forced_includes: Vec.new(),
        defines: if testing: ["ALLOC_TESTING"] else: Vec.new(),
        exclude_basenames: Vec.new(), check_mode: false, diff_mode: false,
        stats_mode: false, no_c_export: true, c_export_functions: false,
        convert_goto_to_structured: false, block_style: 2, width_slice: 8,
        shared_defs: "std.c_algorithms.defs", migrate_one: "",
        shared_fragment: "", ir_roundtrip: false,
    }

fn calg_migrate(ctx: &ActionCtx, label: &str, options: MigrateOptions):
    let workspace = ctx.create_workspace(label)
    var compiler_options = workspace.options()
    compiler_options.prelude_mode = PreludeMode.None
    workspace.set_options(compiler_options)
    workspace.set_migrate_options(options)
    let result = workspace.compile()
    if result.rc != 0: return calg_fail(ctx, label ++ f" exited {result.rc}")
    0

// The generated tree carries no foreign ABI surface and no untranslated
// residue (§No Silent Fallbacks); a migration that lost modules fails the
// floor rather than promoting a partial corpus.
fn calg_reject_bad_output(ctx: &ActionCtx, generated: &str) -> i32:
    let fs = ctx.fs()
    var errors = 0
    var modules = 0
    for path in fs.list_files(generated):
        if not path.ends_with(".w"): continue
        modules = modules + 1
        let text = fs.read_text(path)
        if text.contains("@[c_export("):
            ctx.diagnostics().error("c-algorithms generated source contains a forbidden c_export attribute in " ++ path)
            errors = errors + 1
        if text.contains("// Bail:") or text.contains("[MIGRATOR_UNTRANSLATED]"):
            ctx.diagnostics().error("c-algorithms generated source contains untranslatable migrator output in " ++ path)
            errors = errors + 1
    let floor = calg_modules().len() + 1
    if modules < floor:
        return calg_fail(ctx, f"only {modules} generated .w files under " ++ generated ++ f"; expected at least {floor}")
    errors

// The .wo bundle root (docs/wo_bundles.md "Root"): one `use` per corpus
// module, bytewise by name, so the bundle build reaches every module. The
// text is a pure function of the module listing; c-algorithms-bundle-root-check
// checks the promoted lib/std/c_algorithms/bundle.w against it.
pub fn calg_bundle_root_text(module_paths: &Vec[str]) -> str:
    var names: Vec[str] = Vec.new()
    for path in module_paths:
        if not path.ends_with(".w"): continue
        let name = calg_module_name(path)
        if name == "bundle" or calg_is_harness(name): continue
        var placed = false
        var next: Vec[str] = Vec.new()
        for existing in names:
            if not placed and name < existing:
                next.push(name.clone())
                placed = true
            next.push(existing.clone())
        if not placed: next.push(name.clone())
        names = next
    var text = "// lib/std/c_algorithms/bundle.w — the c-algorithms .wo bundle root (docs/wo_bundles.md).\n"
    text = text ++ "// Written by build/c_algorithms.w (c-algorithms-migrate) from the migrated module list:\n"
    text = text ++ "// one `use` per corpus module; alloc_testing, framework and test_cpp are the harness.\n"
    for name in names: text = text ++ "use std.c_algorithms." ++ name ++ "\n"
    text

// The production and ALLOC_TESTING engines are independent migrations of the
// same pinned sources. The latter retains upstream's allocation-failure oracle.
pub fn run_calg_migrate_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let reference = ctx.inputs()[0]
    let output = ctx.output()
    let source = calg_scratch(ctx) ++ "/source"
    let generated = calg_scratch(ctx) ++ "/generated"
    let testing = ctx.args().len() > 0 and ctx.args()[0] == "testing"
    if calg_reset(ctx, source) != 0 or calg_reset(ctx, generated) != 0: return 1
    for name in calg_modules():
        for extension in [".c", ".h"]:
            if calg_copy(ctx, reference ++ "/src/" ++ name ++ extension, source ++ "/" ++ name ++ extension) != 0: return 1
    for header in ["alt-value-type.h", "libcalg.h"]:
        if calg_copy(ctx, reference ++ "/src/" ++ header, source ++ "/" ++ header) != 0: return 1
    if calg_copy_test_sources(ctx, reference, source) != 0: return 1
    if not testing:
        if calg_copy(ctx, reference ++ "/test/test-cpp.cpp", source ++ "/test-cpp.c") != 0: return 1
    if calg_migrate(ctx, "c-algorithms-engine", calg_options(source, generated, testing)) != 0: return 1
    if testing:
        // Upstream links each test as a separate program, and their external
        // globals are independent (list's variable1 is 50, arraylist's is
        // zero). Each test is therefore its own whole migration of engine,
        // framework and test, with its own shared definitions module.
        for name in calg_tests():
            let basename = "test-" ++ name ++ ".c"
            let upstream = "test-" ++ name ++ (if name == "cpp": ".cpp" else: ".c")
            if calg_copy(ctx, reference ++ "/test/" ++ upstream, source ++ "/" ++ basename) != 0: return 1
            let test_output = generated ++ "/tests/" ++ name
            if fs.mkdir_all(test_output) != 0: return 1
            if calg_migrate(ctx, "c-algorithms-test-" ++ name, calg_options(source, test_output, true)) != 0: return 1
            if fs.remove_file(source ++ "/" ++ basename) != 0: return calg_fail(ctx, "cannot remove staged test " ++ basename)
    else:
        if fs.write_text(generated ++ "/bundle.w", calg_bundle_root_text(fs.list_files(generated))) != 0:
            return calg_fail(ctx, "cannot write the bundle root")
    if calg_copy(ctx, reference ++ "/COPYING", generated ++ "/COPYING") != 0: return 1
    if fs.write_text(generated ++ "/UPSTREAM", CALG_REVISION ++ "\nsha256=" ++ CALG_SHA256 ++ "\n") != 0: return 1
    if fs.exists(output) and fs.remove_tree(output) != 0: return calg_fail(ctx, "cannot replace " ++ output)
    if fs.rename(generated, output) != 0: return calg_fail(ctx, "cannot publish " ++ output)
    0

pub fn run_calg_test_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let generated = ctx.inputs()[0]
    let output = ctx.output()
    if calg_reset(ctx, output) != 0: return 1
    var report = "upstream=" ++ CALG_REVISION ++ "\nconfiguration=ALLOC_TESTING\n"
    for name in calg_tests():
        let module_dir = output ++ "/" ++ name ++ "/lib/std/c_algorithms"
        if fs.mkdir_all(module_dir) != 0: return 1
        for path in fs.list_files(generated ++ "/tests/" ++ name):
            if not path.ends_with(".w"): continue
            if calg_copy(ctx, path, module_dir ++ "/" ++ calg_basename(path)) != 0: return 1
        let test_name = "test_" ++ name.replace("-", "_") ++ ".w"
        let binary = output ++ "/test-" ++ name
        let workspace = ctx.create_workspace("c-algorithms-test-" ++ name)
        workspace.add_file(module_dir ++ "/" ++ test_name)
        var options = workspace.options()
        options.output_path = binary.clone()
        options.prelude_mode = PreludeMode.None
        workspace.set_options(options)
        let compiled = workspace.compile()
        if compiled.rc != 0: return calg_fail(ctx, "compile test-" ++ name ++ f" exited {compiled.rc}")
        let argv: Vec[str] = [calg_abs(ctx, binary)]
        let result = ctx.process_runner().run_capture(argv, calg_abs(ctx, binary ++ ".stdout"), calg_abs(ctx, binary ++ ".stderr"), 300000)
        if result.rc != 0: return calg_fail(ctx, "test-" ++ name ++ f" exited {result.rc}\n" ++ result.stdout ++ result.stderr)
        report = report ++ "PASS test-" ++ name ++ "\n"
        print("PASS test-" ++ name)
    if fs.write_text(output ++ "/report.txt", report) != 0: return 1
    print("upstream=" ++ CALG_REVISION ++ " " ++ f"{calg_tests().len()} programs passed")
    0

pub fn run_calg_check_generated_action(ctx: ActionCtx) -> i32:
    let generated = ctx.inputs()[0]
    if calg_reject_bad_output(ctx, generated) != 0: return 1
    if ctx.fs().write_text(ctx.output(), "ok\n") != 0: return calg_fail(ctx, "cannot write " ++ ctx.output())
    0

// Promotion replaces every module under lib/std/c_algorithms with the
// migration's output: the checked-in corpus is generated, never hand-edited.
pub fn run_calg_promote_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let generated = ctx.inputs()[0]
    let destination = ctx.output()
    if calg_reject_bad_output(ctx, generated) != 0: return 1
    if fs.mkdir_all(destination) != 0: return calg_fail(ctx, "cannot create " ++ destination)
    for path in fs.list_files(destination):
        if path.ends_with(".w") and fs.remove_file(path) != 0: return calg_fail(ctx, "cannot remove " ++ path)
    var copied = 0
    for path in fs.list_files(generated):
        if not path.ends_with(".w"): continue
        if calg_copy(ctx, path, destination ++ "/" ++ calg_basename(path)) != 0: return 1
        copied = copied + 1
    print(f"promoted {copied} generated c-algorithms modules into " ++ calg_abs(ctx, destination))
    0

// The promoted bundle root is exactly what the migrate action writes for the
// corpus listing. Input: the root; arg: the corpus directory.
pub fn run_calg_bundle_root_check_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let root = ctx.inputs()[0]
    let corpus = ctx.args()[0]
    if fs.read_text(root) != calg_bundle_root_text(fs.list_files(corpus)):
        return calg_fail(ctx, root ++ " is not the bundle root the migrate action writes for " ++ corpus ++ " (one `use` per corpus module, sorted; the harness excluded)")
    if fs.write_text(ctx.output(), "ok\n") != 0: return calg_fail(ctx, "cannot write " ++ ctx.output())
    0

pub fn calg_pipeline(out: Build) -> Build:
    let archive = "out/c_algorithms_reference/c-algorithms.tar.gz"
    let extracted = "out/c_algorithms_reference/extracted"
    let reference = extracted ++ "/c-algorithms-" ++ CALG_REVISION
    var graph = out.download("c-algorithms-download", Download {
        url: "https://codeload.github.com/fragglet/c-algorithms/tar.gz/" ++ CALG_REVISION,
        sha256: CALG_SHA256, output_path: archive.clone(),
    })
    graph = graph.extract_tar_gz("c-algorithms-reference", archive, extracted)
    for testing in [false, true]:
        let name = if testing: "c-algorithms-migrate-tests" else: "c-algorithms-migrate"
        let destination = if testing: "out/c_algorithms_tests_migrated" else: "out/c_algorithms_migrated"
        var target = target_new(.Action, name.clone(), "").output(destination)
        target.action = run_calg_migrate_action
        target = target.input(reference.clone()).dep("c-algorithms-reference")
        target = target.write_scope("out/tmp/action-scratch/" ++ name)
        if testing: target = target.arg("testing")
        graph = graph.add_target(target)
    var tests = target_new(.Action, "c-algorithms-test", "").output("out/corpus/c-algorithms-test")
    tests.action = run_calg_test_action
    tests = tests.input("out/c_algorithms_tests_migrated").dep("c-algorithms-migrate-tests")
    graph = graph.add_target(tests)
    var check = target_new(.Action, "c-algorithms-check-generated", "").output("out/gen/.c-algorithms-check-generated-stamp")
    check.action = run_calg_check_generated_action
    check = check.input("out/c_algorithms_migrated").dep("c-algorithms-migrate")
    graph = graph.add_target(check)
    var promote = target_new(.Action, "c-algorithms-promote", "").output("lib/std/c_algorithms")
    promote.action = run_calg_promote_action
    promote = promote.write_scope("out/tmp/action-scratch/c-algorithms-promote")
    promote = promote.input("out/c_algorithms_migrated").dep("c-algorithms-check-generated").dep("c-algorithms-test")
    graph.add_target(promote)
