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

fn calg_fail(ctx: &ActionCtx, message: &str):
    ctx.diagnostics().error(ctx.target_name() ++ ": " ++ message)
    1

fn calg_abs(ctx: &ActionCtx, path: &str): ctx.project_info().project_root() ++ "/" ++ path
fn calg_scratch(ctx: &ActionCtx): "out/tmp/action-scratch/" ++ ctx.target_name()

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
    if testing:
        for name in ["alloc-testing", "framework"]:
            for extension in [".c", ".h"]:
                if calg_copy(ctx, reference ++ "/test/" ++ name ++ extension, source ++ "/" ++ name ++ extension) != 0: return 1
    if calg_migrate(ctx, "c-algorithms-engine", calg_options(source, generated, testing)) != 0: return 1
    if testing:
        // One main at a time, with all engine and framework declarations in
        // the project scan. No test body is rewritten or replaced by a facade.
        for name in calg_tests():
            let basename = "test-" ++ name ++ ".c"
            let upstream = "test-" ++ name ++ (if name == "cpp": ".cpp" else: ".c")
            if calg_copy(ctx, reference ++ "/test/" ++ upstream, source ++ "/" ++ basename) != 0: return 1
            var options = calg_options(source, generated, true)
            options.migrate_one = basename.clone()
            options.shared_fragment = calg_scratch(ctx) ++ "/" ++ name ++ ".shared-fragment"
            if calg_migrate(ctx, "c-algorithms-test-" ++ name, options) != 0: return 1
            if fs.remove_file(source ++ "/" ++ basename) != 0: return calg_fail(ctx, "cannot remove staged test " ++ basename)
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
    let module_dir = output ++ "/lib/std/c_algorithms"
    if fs.mkdir_all(module_dir) != 0: return 1
    for path in fs.list_files(generated):
        if not path.ends_with(".w"): continue
        let parts = path.split("/")
        if calg_copy(ctx, path, module_dir ++ "/" ++ parts[parts.len() - 1]) != 0: return 1
    var report = "upstream=" ++ CALG_REVISION ++ "\nconfiguration=ALLOC_TESTING\n"
    for name in calg_tests():
        let binary = output ++ "/test-" ++ name
        let workspace = ctx.create_workspace("c-algorithms-test-" ++ name)
        workspace.add_file(module_dir ++ "/test_" ++ name.replace("-", "_") ++ ".w")
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
    if fs.write_text(output ++ "/report.txt", report) != 0: return 1
    print(report)
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
    graph.add_target(tests)
