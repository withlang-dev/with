module build.c_algorithms

use std.build
use build.corpus

// fragglet/c-algorithms, ISC (its COPYING ships beside the migration).
// Phase 1 of docs/stdlib_sourcing_plan.md. The generic pipeline
// (build/corpora.w) fetches, migrates, checks, promotes and bundles it;
// this module holds the facts, the staging hook and the corpus's own
// lanes: upstream's 17 test programs, each its own ALLOC_TESTING migration.

const CALG_REVISION = "23d453792ed89a28ed7d2c8d4311a4d9f7822edd"
const CALG_SHA256 = "c2e9f3ba13d5373f79a70fa27d93730de98af314f2476190b156eee2a638a51b"

// The checked-in ALLOC_TESTING migration of upstream's test programs
// (docs/stdlib_sourcing_plan.md: a corpus's migrated tests live in the tree).
// engine/ holds the one engine + framework copy every program shares;
// programs/<name>/ holds the program's own defs.w and test module. Generated
// by c-algorithms-promote-tests, never hand-edited. The programs migrate
// under their own package: a compiler that embeds the c_algorithms bundle
// resolves `std.c_algorithms.*` to the bundle interface before any local
// module, so a program could never supply its own defs there. It stays a
// std package: under --no-prelude, std.libc reaches c_void through the
// std tier's view of the corpus defs (exactly as the bundle builds do), and
// a user package cannot provide that.
const CALG_TESTS_DIR = "test/corpora/c_algorithms"
const CALG_TESTS_PACKAGE = "std.calg_testing"
fn calg_tests_package_dir(): "lib/" ++ CALG_TESTS_PACKAGE.replace(".", "/")

fn calg_modules() -> Vec[str]:
    ["arraylist", "avl-tree", "binary-heap", "binomial-heap", "bloom-filter",
     "compare-int", "compare-pointer", "compare-string", "hash-int",
     "hash-pointer", "hash-string", "hash-table", "list", "queue", "rb-tree",
     "set", "slist", "sortedarray", "trie"]

fn calg_tests() -> Vec[str]:
    ["alloc-testing", "arraylist", "avl-tree", "binary-heap", "binomial-heap",
     "bloom-filter", "cpp", "list", "slist", "queue", "compare-functions",
     "hash-functions", "hash-table", "rb-tree", "set", "trie", "sortedarray"]

fn calg_test_module(name: &str): "test_" ++ name.replace("-", "_") ++ ".w"

pub fn c_algorithms_corpus() -> Corpus:
    Corpus {
        name: "c_algorithms", stem: "c-algorithms", package: "std.c_algorithms",
        corpus_rel: "std/c_algorithms", corpus_dir: "lib/std/c_algorithms",
        upstream: upstream_github("c_algorithms", "fragglet/c-algorithms", CALG_REVISION, CALG_SHA256),
        license: "COPYING",
        // upstream's test framework and its smoke program (test-cpp
        // exercises every module once) ride along in the production corpus
        // as the drift harness; they are never part of the bundle root
        harness: ["alloc_testing", "framework", "test_cpp"], drift_harness: "test_cpp.w", drift_harness_arg: "",
        module_floor: 20, defines: Vec.new(), excludes: Vec.new(),
        promote_after: ["c-algorithms-promote-tests"], test_lane: "c-algorithms-test",
        prepare_reference: corpus_no_prepare, stage: calg_stage,
        migrate: corpus_migrate_directory, finish_generated: corpus_no_finish,
        verify_generated: corpus_no_verify, lanes: calg_lanes,
    }

fn calg_copy_engine_sources(ctx: &ActionCtx, reference: &str, source: &str) -> i32:
    for name in calg_modules():
        for extension in [".c", ".h"]:
            if corpus_copy(ctx, reference ++ "/src/" ++ name ++ extension, source ++ "/" ++ name ++ extension) != 0: return 1
    for header in ["alt-value-type.h", "libcalg.h"]:
        if corpus_copy(ctx, reference ++ "/src/" ++ header, source ++ "/" ++ header) != 0: return 1
    for name in ["alloc-testing", "framework"]:
        for extension in [".c", ".h"]:
            if corpus_copy(ctx, reference ++ "/test/" ++ name ++ extension, source ++ "/" ++ name ++ extension) != 0: return 1
    0

// The production corpus: the engine, the test framework and test-cpp.
fn calg_stage(ctx: &ActionCtx, corpus: &Corpus, reference: &str, source: &str) -> i32:
    if calg_copy_engine_sources(ctx, reference, source) != 0: return 1
    corpus_copy(ctx, reference ++ "/test/test-cpp.cpp", source ++ "/test-cpp.c")

fn calg_tests_options(source: &str, output: &str) -> MigrateOptions:
    MigrateOptions {
        source_path: source.clone(), output_path: output.clone(),
        include_paths: [source.clone()], forced_includes: Vec.new(),
        defines: ["ALLOC_TESTING"], exclude_basenames: Vec.new(), check_mode: false,
        diff_mode: false, stats_mode: false, no_c_export: true, c_export_functions: false,
        convert_goto_to_structured: false, block_style: 2, width_slice: 8,
        shared_defs: CALG_TESTS_PACKAGE ++ ".defs", migrate_one: "",
        shared_fragment: "", ir_roundtrip: false,
    }

// The ALLOC_TESTING migration of every test program: upstream links each
// test as a separate program, and their external globals are independent
// (list's variable1 is 50, arraylist's is zero). Each test is therefore its
// own whole migration of engine, framework and test, with its own shared
// definitions module; it retains upstream's allocation-failure oracle.
pub fn run_calg_migrate_tests_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let reference = ctx.inputs()[0]
    let output = ctx.output()
    let source = corpus_scratch(ctx) ++ "/source"
    let generated = corpus_scratch(ctx) ++ "/generated"
    if corpus_reset_dir(ctx, source) != 0 or corpus_reset_dir(ctx, generated) != 0: return 1
    if calg_copy_engine_sources(ctx, reference, source) != 0: return 1
    for name in calg_tests():
        let basename = "test-" ++ name ++ ".c"
        let upstream = "test-" ++ name ++ (if name == "cpp": ".cpp" else: ".c")
        if corpus_copy(ctx, reference ++ "/test/" ++ upstream, source ++ "/" ++ basename) != 0: return 1
        let test_output = generated ++ "/tests/" ++ name
        if fs.mkdir_all(test_output) != 0: return 1
        if corpus_run_migration(ctx, "c-algorithms-test-" ++ name, calg_tests_options(source, test_output)) != 0: return 1
        if fs.remove_file(source ++ "/" ++ basename) != 0: return corpus_fail(ctx, "cannot remove staged test " ++ basename)
    if fs.write_text(generated ++ "/UPSTREAM", CALG_REVISION ++ "\nsha256=" ++ CALG_SHA256 ++ "\nconfiguration=ALLOC_TESTING\n") != 0: return 1
    if fs.exists(output) and fs.remove_tree(output) != 0: return corpus_fail(ctx, "cannot replace " ++ output)
    if fs.rename(generated, output) != 0: return corpus_fail(ctx, "cannot publish " ++ output)
    0

// Promotes the ALLOC_TESTING test migration into the tree. Every program's
// migration carries its own copy of the engine and framework; those copies
// are byte-identical across programs (the same translation units), so one
// engine/ is checked in and each programs/<name>/ keeps only what differs:
// the program's defs.w (its globals) and its test module.
pub fn run_calg_promote_tests_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let generated = ctx.inputs()[0] ++ "/tests"
    let destination = ctx.output()
    if corpus_reset_dir(ctx, destination) != 0: return 1
    let engine = destination ++ "/engine"
    if fs.mkdir_all(engine) != 0: return corpus_fail(ctx, "cannot create " ++ engine)
    var engine_from = ""
    for name in calg_tests():
        let program = generated ++ "/" ++ name
        let test_module = calg_test_module(name)
        let target = destination ++ "/programs/" ++ name
        if fs.mkdir_all(target) != 0: return corpus_fail(ctx, "cannot create " ++ target)
        for path in fs.list_files(program):
            if not path.ends_with(".w"): continue
            let base = corpus_basename(path)
            if base == "defs.w" or base == test_module:
                if corpus_copy(ctx, path, target ++ "/" ++ base) != 0: return 1
                continue
            let shared = engine ++ "/" ++ base
            if engine_from.len() == 0 or not fs.exists(shared):
                if corpus_copy(ctx, path, shared) != 0: return 1
            else if fs.read_text(shared) != fs.read_text(path):
                return corpus_fail(ctx, "engine module " ++ base ++ " differs between programs " ++ engine_from ++ " and " ++ name ++ "; the shared engine/ layout no longer holds")
        if engine_from.len() == 0: engine_from = name.clone()
    if fs.write_text(destination ++ "/UPSTREAM", CALG_REVISION ++ "\nsha256=" ++ CALG_SHA256 ++ "\nconfiguration=ALLOC_TESTING\n") != 0: return 1
    print(f"promoted {calg_tests().len()} c-algorithms test programs into " ++ corpus_abs(ctx, destination))
    0

// The corpora lane: every checked-in test program is assembled into its own
// module tree, compiled by the release binary and run. The engine's
// allocation oracle asserts inside the program; a non-zero exit is the
// failure.
pub fn run_calg_test_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let compiler = corpus_abs(ctx, ctx.inputs()[0])
    let output = ctx.output()
    if corpus_reset_dir(ctx, output) != 0: return 1
    var report = "upstream=" ++ CALG_REVISION ++ "\nconfiguration=ALLOC_TESTING\n"
    for name in calg_tests():
        let program_root = output ++ "/" ++ name
        let module_dir = program_root ++ "/" ++ calg_tests_package_dir()
        if fs.mkdir_all(module_dir) != 0: return 1
        if corpus_copy_w_files(ctx, CALG_TESTS_DIR ++ "/engine", module_dir) != 0: return 1
        if corpus_copy_w_files(ctx, CALG_TESTS_DIR ++ "/programs/" ++ name, module_dir) != 0: return 1
        let binary = output ++ "/test-" ++ name
        // The program's directory is the project root so its lib/ root holds
        // the package; the release binary's embedded std supplies std.libc.
        // Build-layer code is compiled by the SEED: a collection literal with
        // moved element temporaries is #1122 under seeds before 9ccd1e2d.
        var compile_args: Vec[str] = Vec.new()
        compile_args.push(compiler.clone())
        compile_args.push("build")
        compile_args.push("--no-prelude")
        compile_args.push("-O1")
        compile_args.push(calg_tests_package_dir() ++ "/" ++ calg_test_module(name))
        compile_args.push("-o")
        compile_args.push(corpus_abs(ctx, binary))
        let compiled = ctx.process_runner().run_capture_cwd(compile_args, corpus_abs(ctx, binary ++ ".compile.stdout"), corpus_abs(ctx, binary ++ ".compile.stderr"), 600000, corpus_abs(ctx, program_root))
        if compiled.rc != 0: return corpus_fail(ctx, "compile test-" ++ name ++ f" exited {compiled.rc}\n" ++ fs.read_text(binary ++ ".compile.stderr"))
        var argv: Vec[str] = Vec.new()
        argv.push(corpus_abs(ctx, binary))
        let result = ctx.process_runner().run_capture(argv, corpus_abs(ctx, binary ++ ".stdout"), corpus_abs(ctx, binary ++ ".stderr"), 300000)
        if result.rc != 0: return corpus_fail(ctx, "test-" ++ name ++ f" exited {result.rc}\n" ++ result.stdout ++ result.stderr)
        report = report ++ "PASS test-" ++ name ++ "\n"
        print("PASS test-" ++ name)
    if fs.write_text(output ++ "/report.txt", report) != 0: return 1
    print("upstream=" ++ CALG_REVISION ++ " " ++ f"{calg_tests().len()} programs passed")
    0

// Every checked-in test program file is an input: an edit re-runs the lane.
fn calg_with_test_inputs(target: Target, ctx: &BuildCtx) -> Target:
    var out = target
    for path in ctx.fs().list_files(CALG_TESTS_DIR):
        if path.ends_with(".w"): out = out.input(path.clone())
    out

fn calg_lanes(out: Build, ctx: &BuildCtx, corpus: &Corpus, release_compiler: &str) -> Build:
    var graph = out
    var migrate_tests = target_new(.Action, "c-algorithms-migrate-tests", "").output("out/c_algorithms_tests_migrated")
    migrate_tests.action = run_calg_migrate_tests_action
    migrate_tests = migrate_tests.input(corpus.upstream.reference.clone()).dep("c-algorithms-prepare-reference")
    migrate_tests = migrate_tests.write_scope("out/tmp/action-scratch/c-algorithms-migrate-tests")
    graph = graph.add_target(migrate_tests)
    var promote_tests = target_new(.Action, "c-algorithms-promote-tests", "").output(CALG_TESTS_DIR)
    promote_tests.action = run_calg_promote_tests_action
    promote_tests = promote_tests.input("out/c_algorithms_tests_migrated").dep("c-algorithms-migrate-tests")
    graph = graph.add_target(promote_tests)
    var tests = target_new(.Action, "c-algorithms-test", "").output("out/corpus/c-algorithms-test")
    tests.action = run_calg_test_action
    tests = tests.input(release_compiler.clone()).dep("build")
    tests = calg_with_test_inputs(move tests, ctx)
    graph.add_target(tests)
