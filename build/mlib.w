module build.mlib

use std.build
use build.corpus

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
        fresh_test_lanes: ["mlib-test-fresh"], extra_generated_dirs: List.new(),
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

fn mlib_lanes(out: Build, ctx: &BuildCtx, corpus: &Corpus, release_compiler: &str) -> Build:
    var tests = target_new(.Action, "mlib-test", "").output("out/corpus/mlib-test")
    tests.action = run_mlib_test_action
    tests = tests.input(release_compiler).input("lib/std/engines/mlib/multimap.w").dep("build")
    var fresh = target_new(.Action, "mlib-test-fresh", "").output("out/corpus/mlib-test-fresh")
    fresh.action = run_mlib_test_fresh_action
    fresh = fresh.input(release_compiler).input("out/mlib_migrated").dep("build").dep("mlib-migrate")
    out.add_target(tests).add_target(fresh)
