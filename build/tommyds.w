module build.tommyds

use std.build
use build.corpus

// TommyDS v3.0 (amadvance/tommyds), BSD-2-Clause (its LICENSE ships beside
// the migration). Phase 2 of docs/stdlib_sourcing_plan.md. The generic
// pipeline (build/corpora.w) fetches, migrates, checks, promotes and
// bundles it; this module holds the facts and the two hooks TommyDS needs.

// Upstream compiles tommy.c, which #includes every other .c, as one unit;
// the corpus migrates the units themselves so each structure is a module.
fn tommy_modules() -> Vec[str]:
    ["tommyalloc", "tommyarray", "tommyarrayblk", "tommyarrayblkof",
     "tommyarrayof", "tommyhash", "tommyhashdyn", "tommyhashlin",
     "tommyhashtbl", "tommylist", "tommytree", "tommytrie", "tommytrieinp"]

fn tommy_headers() -> Vec[str]: ["tommy", "tommychain", "tommytypes"]

pub fn tommyds_corpus() -> Corpus:
    Corpus {
        name: "tommyds", stem: "tommyds", package: "std.tommyds",
        corpus_rel: "std/tommyds", corpus_dir: "lib/std/tommyds",
        upstream: upstream_github("tommyds", "amadvance/tommyds", "1f3727fc89174902c48e3933ac4610cb7fb13f4a",
            "cf2036f73af8a5e20e50b42d36352ec932d6eee7b7e847bebeef2efd296385d3"),
        license: "LICENSE",
        // upstream's check program is the corpus's test: it rides in the
        // promoted corpus as the drift harness and the corpora lane's
        // program, never in the bundle root (`check` collides with the
        // prelude name, so the migrator spells the module check_)
        harness: ["check_"], drift_harness: "check_.w", drift_harness_arg: "",
        module_floor: 14, defines: Vec.new(), excludes: Vec.new(),
        promote_after: Vec.new(), test_lane: "tommyds-test",
        prepare_reference: corpus_no_prepare, stage: tommy_stage,
        migrate: corpus_migrate_directory, finish_generated: corpus_no_finish,
        verify_generated: corpus_no_verify, lanes: tommy_lanes,
    }

// Flat staging: the units and headers side by side, plus a tommyds/ header
// directory so check.c's `#include "tommyds/tommy.h"` resolves.
fn tommy_stage(ctx: &ActionCtx, corpus: &Corpus, reference: &str, source: &str) -> i32:
    if ctx.fs().mkdir_all(source ++ "/tommyds") != 0: return corpus_fail(ctx, "cannot create the header directory")
    for name in tommy_modules():
        for extension in [".c", ".h"]:
            if corpus_copy(ctx, reference ++ "/tommyds/" ++ name ++ extension, source ++ "/" ++ name ++ extension) != 0: return 1
        if corpus_copy(ctx, reference ++ "/tommyds/" ++ name ++ ".h", source ++ "/tommyds/" ++ name ++ ".h") != 0: return 1
    for name in tommy_headers():
        if corpus_copy(ctx, reference ++ "/tommyds/" ++ name ++ ".h", source ++ "/" ++ name ++ ".h") != 0: return 1
        if corpus_copy(ctx, reference ++ "/tommyds/" ++ name ++ ".h", source ++ "/tommyds/" ++ name ++ ".h") != 0: return 1
    corpus_copy(ctx, reference ++ "/check.c", source ++ "/check.c")

// The corpora lane: upstream's check program, compiled from the checked-in
// corpus by the release binary against the embedded bundle, then run. It
// asserts internally and exits non-zero on any failure.
pub fn run_tommy_test_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let compiler = corpus_abs(ctx, ctx.inputs()[0])
    let output = ctx.output()
    if corpus_reset_dir(ctx, output) != 0: return 1
    let binary = output ++ "/tommycheck"
    // Build-layer code runs on the seed: argv is pushed (#1122).
    var compile_args: Vec[str] = Vec.new()
    compile_args.push(compiler.clone())
    compile_args.push("build")
    compile_args.push("-O1")
    compile_args.push("lib/std/tommyds/check_.w")
    compile_args.push("-o")
    compile_args.push(corpus_abs(ctx, binary))
    let compiled = ctx.process_runner().run_capture(compile_args, corpus_abs(ctx, binary ++ ".compile.stdout"), corpus_abs(ctx, binary ++ ".compile.stderr"), 600000)
    if compiled.rc != 0: return corpus_fail(ctx, f"compile tommycheck exited {compiled.rc}\n" ++ fs.read_text(binary ++ ".compile.stderr"))
    var argv: Vec[str] = Vec.new()
    argv.push(corpus_abs(ctx, binary))
    let result = ctx.process_runner().run_capture(argv, corpus_abs(ctx, binary ++ ".stdout"), corpus_abs(ctx, binary ++ ".stderr"), 600000)
    if result.rc != 0: return corpus_fail(ctx, f"tommycheck exited {result.rc}\n" ++ result.stdout ++ result.stderr)
    if fs.write_text(output ++ "/report.txt", "upstream=1f3727fc89174902c48e3933ac4610cb7fb13f4a\nPASS tommycheck\n") != 0: return 1
    print("tommycheck passed")
    0

fn tommy_lanes(out: Build, ctx: &BuildCtx, corpus: &Corpus, release_compiler: &str) -> Build:
    var tests = target_new(.Action, "tommyds-test", "").output("out/corpus/tommyds-test")
    tests.action = run_tommy_test_action
    tests = tests.input(release_compiler.clone()).input("lib/std/tommyds/check_.w").dep("build")
    out.add_target(tests)
