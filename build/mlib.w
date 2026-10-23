module build.mlib

use std.build
use build.corpus
use build.wo

// M*LIB (P-p-H-d/mlib), BSD-2-Clause (its LICENSE ships beside the
// migration). Phase 4 of docs/proposals/stdlib_sourcing_plan.md: the
// B+tree (`m-bptree.h`) behind `BTreeMap` and `BTreeSet`. The generic
// pipeline (build/corpora.w) fetches, migrates, checks, promotes and bundles
// it; this module holds the facts, the staging hook and the corpus's lanes.
//
// M*LIB is header-only: every container is a template a unit instantiates
// (`BPTREE_DEF2(name, N, key, value)`), so the corpus's own units are the
// facade shapes unit (the standard library's instantiations, D148) and
// upstream's multimap example as the drift harness. `M_USE_STDIO=0` keeps
// the stdio parsers and printers out (they are `FILE*` formatters With does
// not model), and `M_RAISE_FATAL` is then the library's allocation-failure
// report, which the corpus makes an abort.

const MLIB_REVISION = "93cddfb56c32976d8aeefd45ef9094167f64b285"
const MLIB_SHA256 = "21d740a10b6ad4210ff4c9c044ef72ba47af5cd57eeb9b7804531bf5add06492"

fn mlib_headers() -> List[str]: ["m-core", "m-bptree"]

pub fn mlib_corpus() -> Corpus:
    Corpus {
        name: "mlib", stem: "mlib", package: "std.engines.mlib",
        corpus_rel: "std/engines/mlib", corpus_dir: "lib/std/engines/mlib",
        upstream: upstream_github("mlib", "P-p-H-d/mlib", MLIB_REVISION, MLIB_SHA256),
        license: "LICENSE",
        // upstream's multimap example is the drift harness: a program over a
        // B+tree instantiated in the program, never part of the bundle root
        harness: ["multimap"], drift_harness: "multimap.w", drift_harness_arg: "",
        module_floor: 2, defines: ["M_USE_STDIO=0", "M_RAISE_FATAL(...)=abort()"], excludes: List.new(),
        include_dirs: List.new(), declared_externs: List.new(), forced_includes: ["stdio.h"],
        promote_after: List.new(), test_lane: "mlib-test",
        fresh_test_lanes: ["mlib-test-fresh", "mlib-test-programs-fresh"], extra_generated_dirs: List.new(),
        prepare_reference: corpus_no_prepare, stage: mlib_stage,
        migrate: corpus_migrate_directory, finish_generated: corpus_no_finish,
        verify_generated: corpus_no_verify, lanes: mlib_lanes,
    }

// The facade shapes unit (docs/proposals/stdlib_sourcing_plan.md, Phase 4;
// D148): M*LIB's B+tree instantiated for the standard library's facades. An
// arbitrary With key rides the slot shape: the engine orders pointers to
// facade-owned slots whose head holds the C-ABI comparison that dispatches
// to the With comparator (std.collections.mlib_slot). A map's value lives
// in the same slot after the key, so one ordered set of slots serves
// `BTreeMap` and `BTreeSet`. The node rank follows upstream's guidance for
// pointer-sized keys. The shape set is extended here, never in migrated code.
fn mlib_facade_shapes_source() -> str:
    "// The facade shapes: M*LIB's B+tree instantiated for the With standard\n" ++
    "// library's facades (docs/proposals/stdlib_sourcing_plan.md, Phase 4). An\n" ++
    "// arbitrary With key rides the slot shape: the engine orders pointers to\n" ++
    "// slots whose head holds the C-ABI callbacks. A B+tree copies keys into\n" ++
    "// its internal nodes as separators, so a stored slot is the engine's own\n" ++
    "// (INIT_SET clones through the With callback, CLEAR drops), and every\n" ++
    "// slot points back at the facade's entry.\n" ++
    "// The instantiation is this unit's exported definitions (M_USE_DECL +\n" ++
    "// M_USE_DEF: `extern`, not `static inline`), so the facades reach them\n" ++
    "// through the corpus interface.\n" ++
    "#define M_USE_DECL\n" ++
    "#define M_USE_DEF\n" ++
    "#include <stdint.h>\n" ++
    "#include <stddef.h>\n" ++
    "#include \"m-core.h\"\n" ++
    "#include \"m-bptree.h\"\n" ++
    "\n" ++
    "typedef struct mlib_slot_head {\n" ++
    "    int (*cmp)(const void*, const void*);\n" ++
    "    void* (*clone)(const void*);\n" ++
    "    void (*drop)(void*);\n" ++
    "    void* entry;\n" ++
    "} mlib_slot_head;\n" ++
    "typedef mlib_slot_head* mlib_slot;\n" ++
    "\n" ++
    "static inline mlib_slot mlib_slot_clone(mlib_slot s) { return (mlib_slot) s->clone(s); }\n" ++
    "static inline void mlib_slot_release(mlib_slot s) { s->drop(s); }\n" ++
    "#define MLIB_SLOT_CMP(a, b) ((a)->cmp((a), (b)))\n" ++
    "#define MLIB_SLOT_INIT_SET(dst, src) ((dst) = mlib_slot_clone(src))\n" ++
    "#define MLIB_SLOT_SET(dst, src) (mlib_slot_release(dst), (dst) = mlib_slot_clone(src))\n" ++
    "#define MLIB_SLOT_CLEAR(s) mlib_slot_release(s)\n" ++
    "#define MLIB_SLOT_OPLIST (INIT(M_INIT_DEFAULT), INIT_SET(MLIB_SLOT_INIT_SET), SET(MLIB_SLOT_SET), CLEAR(MLIB_SLOT_CLEAR), EQUAL(M_EQUAL_DEFAULT), SWAP(M_SWAP_DEFAULT), INIT_MOVE(M_SET_DEFAULT), MOVE(M_SET_DEFAULT), CMP(MLIB_SLOT_CMP), TYPE(mlib_slot))\n" ++
    "\n" ++
    "BPTREE_DEF(mlib_slot_tree, 16, mlib_slot, MLIB_SLOT_OPLIST)\n"

// Flat staging: the two headers beside the units.
fn mlib_stage(ctx: &ActionCtx, corpus: &Corpus, reference: &str, source: &str) -> i32:
    for name in mlib_headers():
        if corpus_copy(ctx, reference ++ "/" ++ name ++ ".h", source ++ "/" ++ name ++ ".h") != 0: return 1
    if ctx.fs().write_text(source ++ "/facade_shapes.c", mlib_facade_shapes_source()) != 0: return corpus_fail(ctx, "cannot write the facade shapes unit")
    corpus_copy(ctx, reference ++ "/example/ex-bptree02.c", source ++ "/multimap.c")

// The corpora lane: upstream's multimap example, compiled from the
// checked-in corpus by the release binary against the embedded bundle, then
// run; its output is the sorted multimap, compared to the expected text.
pub fn run_mlib_test_action(ctx: ActionCtx) -> i32:
    let output = ctx.output()
    if corpus_reset_dir(ctx, output) != 0: return 1
    mlib_compile_and_run(ctx, ["build", "-O1", "lib/std/engines/mlib/multimap.w"], ".")

// D112: the same program on a fresh migration, for the migrator gate.
pub fn run_mlib_test_fresh_action(ctx: ActionCtx) -> i32:
    let output = ctx.output()
    if corpus_reset_dir(ctx, output) != 0: return 1
    let tree = output ++ "/tree"
    if corpus_reset_dir(ctx, tree ++ "/lib/std/engines/mlib") != 0: return 1
    if corpus_copy_w_files(ctx, ctx.inputs()[1], tree ++ "/lib/std/engines/mlib") != 0: return 1
    mlib_compile_and_run(ctx, ["build", "-O1", "lib/std/engines/mlib/multimap.w", "--bundle-corpus", "std/engines/mlib"], tree)

fn mlib_compile_and_run(ctx: &ActionCtx, build_args: List[str], cwd: &str) -> i32:
    let fs = ctx.fs()
    let compiler = corpus_abs(ctx, ctx.inputs()[0])
    let output = ctx.output()
    let binary = output ++ "/multimap"
    var compile_args: List[str] = List.new()
    compile_args.push(compiler)
    for arg in build_args: compile_args.push(arg)
    compile_args.push("-o")
    compile_args.push(corpus_abs(ctx, binary))
    let compiled = ctx.process_runner().run_capture_cwd(compile_args, corpus_abs(ctx, binary ++ ".compile.stdout"), corpus_abs(ctx, binary ++ ".compile.stderr"), 600000, corpus_abs(ctx, cwd))
    if compiled.rc != 0: return corpus_fail(ctx, f"compile multimap exited {compiled.rc}\n" ++ fs.read_text(binary ++ ".compile.stderr"))
    // #2230: name what runs before it runs — the compiler and the binary.
    if corpus_provenance(ctx, output, ctx.inputs()[0]) != 0: return 1
    if corpus_provenance(ctx, output, binary) != 0: return 1
    var argv: List[str] = List.new()
    argv.push(corpus_abs(ctx, binary))
    let result = ctx.process_runner().run_capture(argv, corpus_abs(ctx, binary ++ ".stdout"), corpus_abs(ctx, binary ++ ".stderr"), 600000)
    if result.rc != 0: return corpus_fail(ctx, f"multimap exited {result.rc}\n" ++ result.stdout ++ result.stderr)
    // Key 7 is set in all three fills (7, 49, 343, newest first), key 6 once.
    for expected in ["Key=6 Count=1 Value=6 \n", "Key=7 Count=3 Value=343 Value=49 Value=7 \n", "Key=100 Count=0 \n"]:
        if not result.stdout.contains(expected): return corpus_fail(ctx, "multimap output lacks '" ++ expected ++ "'\n" ++ result.stdout)
    if fs.write_text(output ++ "/report.txt", "upstream=" ++ MLIB_REVISION ++ "\nPASS multimap\n") != 0: return 1
    print("multimap passed")
    0

// ── upstream's B+tree test (the Phase 4 gate) ─────────────────────────
//
// `tests/test-mbptree.c` is migrated whole with m-core.h, m-string.h,
// m-bptree.h, tests/test-obj.h and tests/coverage.h beside it: one program,
// its own `main`, the exit code its verdict. Its configuration is
// upstream's test configuration, `M_USE_STDIO=1` (tests/test-obj.h parses
// with fscanf outside any M_USE_STDIO guard), unlike the library corpus's;
// `coverage.h` leaves M_ASSERT in place without BUILD_COVERAGE. The
// program is checked in under test/corpora/mlib and compiled by the release
// binary with the prelude off (modeled on build/stc.w's test lane).
const MLIB_TESTS_DIR = "test/corpora/mlib"
fn mlib_test_programs() -> List[str]: ["test_mbptree"]
fn mlib_test_headers() -> List[str]: ["m-core", "m-string", "m-bptree"]

fn mlib_test_migrate_argv(ctx: &ActionCtx, compiler: &str, source: &str, output: &str) -> List[str]:
    var argv: List[str] = List.new()
    argv.push(corpus_abs(ctx, compiler))
    argv.push("migrate")
    argv.push(source ++ "/test_mbptree.c")
    argv.push("-o")
    argv.push(output)
    argv.push("--c-target")
    argv.push(corpus_c_model_target())
    argv.push("--c-sysroot")
    argv.push(corpus_abs(ctx, corpus_c_model_dir()))
    argv.push("-I")
    argv.push(source)
    argv.push("-include")
    argv.push("stdio.h")
    argv.push("-D")
    argv.push("M_USE_STDIO=1")
    argv.push("-D")
    argv.push("M_RAISE_FATAL(...)=abort()")
    argv.push("--macro-prefix-map")
    argv.push(source ++ "/=")
    argv.push("--no-prelude")
    argv.push("--no-c-export")
    argv.push("--prefer-brace")
    argv.push("--width-slice")
    argv.push("8")
    argv

pub fn run_mlib_migrate_tests_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let reference = ctx.inputs()[0]
    let output = ctx.output()
    let scratch = corpus_scratch(ctx)
    let generated = scratch ++ "/generated"
    if corpus_reset_dir(ctx, generated) != 0: return 1
    let migrator = corpus_migrator_arg(ctx)
    if migrator.len() == 0: return corpus_fail(ctx, "a corpus migration names its migrator (corpus_migrating_target)")
    for name in mlib_test_programs():
        let source = scratch ++ "/source-" ++ name
        if corpus_reset_dir(ctx, source) != 0: return 1
        for header in mlib_test_headers():
            if corpus_copy(ctx, reference ++ "/" ++ header ++ ".h", source ++ "/" ++ header ++ ".h") != 0: return 1
        for helper in ["test-obj.h", "coverage.h"]:
            if corpus_copy(ctx, reference ++ "/tests/" ++ helper, source ++ "/" ++ helper) != 0: return 1
        if corpus_copy(ctx, reference ++ "/tests/test-mbptree.c", source ++ "/" ++ name ++ ".c") != 0: return 1
        let test_output = generated ++ "/tests/" ++ name
        if fs.mkdir_all(test_output) != 0: return 1
        let label = "mlib-test-" ++ name
        let stdout = corpus_abs(&ctx, scratch ++ "/" ++ label ++ ".stdout")
        let stderr = corpus_abs(&ctx, scratch ++ "/" ++ label ++ ".stderr")
        let migrated = ctx.process_runner().run_capture_cwd(mlib_test_migrate_argv(&ctx, migrator, corpus_abs(&ctx, source), corpus_abs(&ctx, test_output ++ "/" ++ name ++ ".w")), stdout, stderr, 1200000, corpus_abs(&ctx, scratch))
        if migrated.rc != 0: return corpus_fail(ctx, label ++ f": `migrate` exited {migrated.rc}; see " ++ stderr)
    if fs.write_text(generated ++ "/UPSTREAM", MLIB_REVISION ++ "\nsha256=" ++ MLIB_SHA256 ++ "\nconfiguration=tests\n") != 0: return 1
    if fs.exists(output) and fs.remove_tree(output) != 0: return corpus_fail(ctx, "cannot replace " ++ output)
    if fs.rename(generated, output) != 0: return corpus_fail(ctx, "cannot publish " ++ output)
    print(f"migrated {mlib_test_programs().len()} M*LIB test program(s) into " ++ corpus_abs(ctx, output))
    0

// The promoted program: test/corpora/mlib/programs/<name>/<name>.w and
// UPSTREAM, published whole.
pub fn run_mlib_promote_tests_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let generated = ctx.inputs()[0] ++ "/tests"
    let final_destination = ctx.output()
    let destination = corpus_scratch(ctx) ++ "/promoted"
    if corpus_reset_dir(ctx, destination) != 0: return 1
    for name in mlib_test_programs():
        let target = destination ++ "/programs/" ++ name
        if fs.mkdir_all(target) != 0: return corpus_fail(ctx, "cannot create " ++ target)
        if corpus_copy(ctx, generated ++ "/" ++ name ++ "/" ++ name ++ ".w", target ++ "/" ++ name ++ ".w") != 0: return 1
    if fs.write_text(destination ++ "/UPSTREAM", MLIB_REVISION ++ "\nsha256=" ++ MLIB_SHA256 ++ "\nconfiguration=tests\n") != 0: return 1
    if fs.exists(final_destination) and fs.remove_tree(final_destination) != 0: return corpus_fail(ctx, "cannot replace " ++ final_destination)
    if fs.rename(destination, final_destination) != 0: return corpus_fail(ctx, "cannot publish " ++ final_destination)
    print("promoted " ++ f"{mlib_test_programs().len()}" ++ " M*LIB test program(s) into " ++ corpus_abs(ctx, final_destination))
    0

// Each program compiled by the release binary with the prelude off and
// run; a nonzero exit is the test's own failed assertion. `fresh=<dir>`
// runs the fresh migration for the migrator gate (D112).
pub fn run_mlib_test_programs_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let compiler = corpus_abs(ctx, ctx.inputs()[0])
    let output = ctx.output()
    if corpus_reset_dir(ctx, output) != 0: return 1
    if corpus_provenance(ctx, output, ctx.inputs()[0]) != 0: return 1
    let fresh = wo_arg_value(ctx.args(), "fresh=")
    var report = "upstream=" ++ MLIB_REVISION ++ "\nconfiguration=tests\n"
    for name in mlib_test_programs():
        let program = if fresh.len() > 0: fresh ++ "/tests/" ++ name ++ "/" ++ name ++ ".w" else: MLIB_TESTS_DIR ++ "/programs/" ++ name ++ "/" ++ name ++ ".w"
        let binary = output ++ "/" ++ name ++ ".bin"
        var compile_args: List[str] = List.new()
        compile_args.push(compiler)
        compile_args.push("build")
        compile_args.push("--no-prelude")
        compile_args.push("-O1")
        compile_args.push(corpus_abs(ctx, program))
        compile_args.push("-o")
        compile_args.push(corpus_abs(ctx, binary))
        let compiled = ctx.process_runner().run_capture_cwd(compile_args, corpus_abs(ctx, binary ++ ".compile.stdout"), corpus_abs(ctx, binary ++ ".compile.stderr"), 600000, ".")
        if compiled.rc != 0: return corpus_fail(ctx, "compile " ++ name ++ f" exited {compiled.rc}\n" ++ fs.read_text(binary ++ ".compile.stderr"))
        if corpus_provenance(ctx, output, binary) != 0: return 1
        var argv: List[str] = List.new()
        argv.push(corpus_abs(ctx, binary))
        // test_io writes its data files into the working directory.
        let result = ctx.process_runner().run_capture_cwd(argv, corpus_abs(ctx, binary ++ ".stdout"), corpus_abs(ctx, binary ++ ".stderr"), 600000, corpus_abs(ctx, output))
        if result.rc != 0: return corpus_fail(ctx, name ++ f" exited {result.rc}\n" ++ result.stdout ++ result.stderr)
        report = report ++ "PASS " ++ name ++ "\n"
        print("PASS " ++ name)
    if fs.write_text(output ++ "/report.txt", report) != 0: return 1
    0

fn mlib_with_test_inputs(target: Target, ctx: &BuildCtx) -> Target:
    var out = target
    // Before the first promotion the directory does not exist; the lane
    // then has no checked-in program to run and fails at its action.
    if not ctx.fs().exists(MLIB_TESTS_DIR): return out
    for path in ctx.fs().list_files(MLIB_TESTS_DIR):
        if path.ends_with(".w"): out = out.input(path)
    out

fn mlib_lanes(out: Build, ctx: &BuildCtx, corpus: &Corpus, release_compiler: &str) -> Build:
    var graph = out
    var tests = target_new(.Action, "mlib-test", "").output("out/corpus/mlib-test")
    tests.action = run_mlib_test_action
    // `:test` runs the test lane: the multimap example, then upstream's test programs.
    tests = tests.input(release_compiler).input("lib/std/engines/mlib/multimap.w").dep("build").dep("mlib-test-programs")
    graph = graph.add_target(tests)
    var fresh = target_new(.Action, "mlib-test-fresh", "").output("out/corpus/mlib-test-fresh")
    fresh.action = run_mlib_test_fresh_action
    fresh = fresh.input(release_compiler).input("out/mlib_migrated").dep("build").dep("mlib-migrate")
    graph = graph.add_target(fresh)
    var migrate_tests = target_new(.Action, "mlib-migrate-tests", "").output("out/mlib_tests_migrated")
    migrate_tests.action = run_mlib_migrate_tests_action
    migrate_tests = migrate_tests.input(corpus.upstream.reference).dep("mlib-prepare-reference")
    migrate_tests = migrate_tests.write_scope("out/tmp/action-scratch/mlib-migrate-tests")
    migrate_tests = corpus_migrating_target(migrate_tests, release_compiler)
    graph = graph.add_target(migrate_tests)
    var promote_tests = target_new(.Action, "mlib-promote-tests", "").output(MLIB_TESTS_DIR)
    promote_tests.action = run_mlib_promote_tests_action
    promote_tests = promote_tests.input("out/mlib_tests_migrated").dep("mlib-migrate-tests")
    graph = graph.add_target(promote_tests)
    var programs = target_new(.Action, "mlib-test-programs", "").output("out/corpus/mlib-test-programs")
    programs.action = run_mlib_test_programs_action
    programs = programs.input(release_compiler).dep("build")
    programs = mlib_with_test_inputs(programs, ctx)
    graph = graph.add_target(programs)
    var programs_fresh = target_new(.Action, "mlib-test-programs-fresh", "").output("out/corpus/mlib-test-programs-fresh")
    programs_fresh.action = run_mlib_test_programs_action
    programs_fresh = programs_fresh.input(release_compiler).input("out/mlib_tests_migrated").arg("fresh=out/mlib_tests_migrated")
    programs_fresh = programs_fresh.dep("build").dep("mlib-migrate-tests")
    programs_fresh = mlib_with_test_inputs(programs_fresh, ctx)
    graph.add_target(programs_fresh)
