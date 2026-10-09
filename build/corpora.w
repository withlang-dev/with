module build.corpora

use std.build
use build.corpus
use build.wo
use build.pcre2
use build.zlib
use build.c_algorithms
use build.tommyds
use std.crypto.sha256

// The corpus registry (docs/spec/toolchain/wo_bundles.md, docs/proposals/stdlib_sourcing_plan.md):
// every migrated C corpus the tree carries, in bundle order. build.w, the
// embedding, the exclusions, the stage/cross/release wiring and the lanes
// all iterate it, so a corpus is present everywhere it must be by
// construction. Adding a library is one line here plus its declaration
// module under build/; nothing else names it. Indexed, not a Vec: a Corpus
// is ephemeral (its hooks take references), and the seed's comptime
// evaluator iterates a Vec of ephemeral records as strings.
pub fn corpus_count() -> i32: 4

pub fn corpus_at(index: i32) -> Corpus:
    if index == 0: return pcre2_corpus()
    if index == 1: return zlib_corpus()
    if index == 2: return c_algorithms_corpus()
    tommyds_corpus()

pub fn corpus_by_name(name: &str) -> Corpus:
    for i in 0..corpus_count():
        if corpus_at(i).name == name: return corpus_at(i)
    // The registry is the only source of names; an unknown one is a build
    // layer bug, never a runtime condition to degrade.
    panic("build/corpora.w: unknown corpus '" ++ name ++ "'")

/// A bundled corpus is provided by its .wo, never embedded as source.
pub fn corpora_source_excluded(path: &str) -> bool:
    for i in 0..corpus_count():
        if path.starts_with(corpus_at(i).corpus_dir ++ "/"): return true
    false

/// The corpus directories, for actions that cannot reach the registry
/// (build/runtime.w takes them as `exclude=` args).
pub fn corpora_exclude_args(target: Target) -> Target:
    var out = target
    for i in 0..corpus_count(): out = out.arg("exclude=" ++ corpus_at(i).corpus_dir ++ "/")
    out

pub fn corpus_bundle_plan(ctx: &BuildCtx, corpus: &Corpus) -> WoBundle:
    wo_bundle_plan(ctx, corpus.name, corpus.corpus_rel, corpus.corpus_dir ++ "/bundle.w")

/// One host bundle plan per corpus, in registry order.
pub fn corpora_bundle_plans(ctx: &BuildCtx) -> Vec[WoBundle]:
    var plans: Vec[WoBundle] = Vec.new()
    for i in 0..corpus_count():
        let corpus = corpus_at(i)
        plans.push(corpus_bundle_plan(ctx, corpus))
    plans

// ── generic actions ─────────────────────────────────────────────
// Every action names its corpus in its first arg.

fn action_corpus(ctx: &ActionCtx) -> Corpus: corpus_by_name(ctx.args()[0])

// A hook is read through a reference so the record stays whole (D32: a
// field read from an owned record moves it).

fn corpus_migrated_dir(corpus: &Corpus) -> str: "out/" ++ corpus.name ++ "_migrated"

pub fn run_corpus_prepare_reference_action(ctx: ActionCtx) -> i32:
    let owned = action_corpus(ctx)
    let corpus = &owned
    let reference = corpus.upstream.reference.clone()
    if not ctx.fs().is_dir(reference): return corpus_fail(ctx, "missing reference tree " ++ reference)
    // D63: a `fn` field is not Copy, so `let prepare = corpus.prepare_reference`
    // through the borrow binds the field place; calling through that alias is
    // #1635 (the build runner's own compile died here) — call through the field.
    if corpus.prepare_reference(&ctx, corpus, &reference) != 0: return 1
    if ctx.fs().write_text(ctx.output(), "ok\n") != 0: return corpus_fail(ctx, "cannot write " ++ ctx.output())
    0

/// Stage, migrate, finish and write the root into `generated`: the
/// corpus's modules exactly as promotion would copy them.
fn corpus_generate(ctx: &ActionCtx, corpus: &Corpus, generated: &str) -> i32:
    let reference = corpus.upstream.reference.clone()
    let source = corpus_scratch(ctx) ++ "/source"
    // #2060: a corpus is migrated against the C model, which only the
    // process path names; a driver migration would be the host's.
    if corpus_migrator_arg(ctx).len() == 0: return corpus_fail(ctx, "a corpus migration names its migrator (corpus_migrating_target)")
    if corpus_reset_dir(ctx, source) != 0 or corpus_reset_dir(ctx, generated) != 0: return 1
    if corpus.stage(ctx, corpus, &reference, &source) != 0: return 1
    if corpus.migrate(ctx, corpus, &source, generated) != 0: return 1
    if corpus.finish_generated(ctx, corpus, generated) != 0: return 1
    corpus_write_bundle_root(ctx, corpus, generated)

/// Stage, migrate, finish, write the root, record the upstream, publish.
pub fn run_corpus_migrate_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let owned = action_corpus(ctx)
    let corpus = &owned
    let reference = corpus.upstream.reference.clone()
    let output = ctx.output()
    let generated = corpus_scratch(ctx) ++ "/generated"
    if corpus_generate(&ctx, corpus, generated) != 0: return 1
    if corpus.license.len() > 0:
        if corpus_copy(ctx, reference ++ "/" ++ corpus.license, generated ++ "/" ++ corpus.license) != 0: return 1
    if fs.write_text(generated ++ "/UPSTREAM", corpus.upstream.revision ++ "\nsha256=" ++ corpus.upstream.sha256 ++ "\n") != 0: return 1
    if fs.exists(output) and fs.remove_tree(output) != 0: return corpus_fail(ctx, "cannot replace " ++ output)
    if fs.rename(generated, output) != 0: return corpus_fail(ctx, "cannot publish " ++ output)
    print("migrated " ++ corpus.name ++ f": {corpus_count_w_files(ctx, output)} modules in " ++ corpus_abs(ctx, output))
    0

fn corpus_check_generated(ctx: &ActionCtx, corpus: &Corpus, generated: &str, compiler: &str) -> i32:
    if corpus_reject_bad_output(ctx, corpus, generated) != 0: return 1
    if corpus_reject_foreign_symbols(ctx, corpus, generated) != 0: return 1
    corpus.verify_generated(ctx, corpus, generated, compiler)

pub fn run_corpus_check_generated_action(ctx: ActionCtx) -> i32:
    let owned = action_corpus(ctx)
    if corpus_check_generated(ctx, &owned, ctx.inputs()[0], ctx.inputs()[1]) != 0: return 1
    if corpus_check_every_module(ctx, &owned, ctx.inputs()[0], ctx.inputs()[1]) != 0: return 1
    if ctx.fs().write_text(ctx.output(), "ok\n") != 0: return corpus_fail(ctx, "cannot write " ++ ctx.output())
    0

/// Promotion replaces every module under the corpus directory with the
/// migration's output: the checked-in corpus is generated, never hand-edited.
pub fn run_corpus_promote_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let owned = action_corpus(ctx)
    let corpus = &owned
    let generated = ctx.inputs()[0]
    let destination = ctx.output()
    if corpus_check_generated(ctx, corpus, generated, ctx.inputs()[1]) != 0: return 1
    if fs.mkdir_all(destination) != 0: return corpus_fail(ctx, "cannot create " ++ destination)
    for path in fs.list_files(destination):
        if path.ends_with(".w") and fs.remove_file(path) != 0: return corpus_fail(ctx, "cannot remove " ++ path)
    var copied = 0
    for path in fs.list_files(generated):
        if not path.ends_with(".w"): continue
        if corpus_copy(ctx, path, destination ++ "/" ++ corpus_basename(path)) != 0: return 1
        copied = copied + 1
    if corpus_write_stamp(&ctx, corpus) != 0: return 1
    print(f"promoted {copied} generated " ++ corpus.name ++ " modules into " ++ corpus_abs(ctx, destination) ++ " and stamped them (D112)")
    0

/// Regenerates the promoted root from the corpus listing (the tool for a
/// root that predates the generator's current text).
pub fn run_corpus_bundle_root_action(ctx: ActionCtx) -> i32:
    let owned = action_corpus(ctx)
    if corpus_write_bundle_root(ctx, &owned, owned.corpus_dir) != 0: return 1
    if ctx.fs().write_text(ctx.output(), "ok\n") != 0: return corpus_fail(ctx, "cannot write " ++ ctx.output())
    0

/// wo-drift: the promoted root is exactly what the migrate action writes
/// for the corpus listing; a module added without regenerating it, or a
/// hand edit, fails here.
pub fn run_corpus_bundle_root_check_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let owned = action_corpus(ctx)
    let corpus = &owned
    let root = corpus.corpus_dir ++ "/bundle.w"
    if fs.read_text(root) != corpus_bundle_root_text(corpus, fs.list_files(corpus.corpus_dir)):
        return corpus_fail(ctx, root ++ " is not the bundle root the migrate action writes for " ++ corpus.corpus_dir ++ " (one `use` per corpus module, sorted; the harness excluded); run `with build :" ++ corpus.stem ++ "-bundle-root`")
    if fs.write_text(ctx.output(), "ok\n") != 0: return corpus_fail(ctx, "cannot write " ++ ctx.output())
    0

fn corpus_w_names(ctx: &ActionCtx, dir: &str) -> Vec[str]:
    var names: Vec[str] = Vec.new()
    for path in ctx.fs().list_files(dir):
        if path.ends_with(".w") and not path.slice(dir.len() + 1, path.len()).contains("/"): names.push(corpus_basename(path))
    corpus_sorted(names)

// ── D112: the migrator is a pinned input of each corpus ─────────
//
// A corpus records the migrator generation that produced it and a hash of
// its modules (corpus.stamp, written by promotion). Batteries check the
// hash (integrity) and run upstream's tests (the lanes); they never
// re-migrate to compare. A corpus re-promotes when its upstream pin moves,
// when its migrator pin is bumped for a fix it needs, or when a language
// ruling breaks or obsoletes its output. A migrator change is gated by
// `corpus-migrator-gate`: every corpus migrated afresh into scratch,
// type-checked and tested there, nothing promoted.

/// The sources that make up `with migrate`; their hash names a migrator
/// generation.
fn corpus_migrator_sources() -> Vec[str]:
    ["src/CImport.w", "src/CiMigrate.w", "src/CiIR.w", "src/CiPrint.w", "src/Migrate.w", "src/compiler/ClangBridge.w", "src/compiler/ClangDriver.w"]

fn corpus_sha256_text(text: &str) -> str:
    var digest: [32]u8 = [0 as u8; 32]
    sha256_hash_str(text, &raw mut digest[0] as *mut u8)
    sha256_hex(&digest[0] as *const u8)

fn corpus_migrator_generation(ctx: &ActionCtx) -> str:
    var listing = ""
    for path in corpus_migrator_sources(): listing = listing ++ path ++ "\t" ++ ctx.fs().sha256_file(path) ++ "\n"
    corpus_sha256_text(listing)

/// One directory's modules, by path and content.
fn corpus_dir_listing(ctx: &ActionCtx, dir: &str) -> str:
    var listing = ""
    for path in corpus_sorted(ctx.fs().list_files(dir)):
        if path.ends_with(".w"): listing = listing ++ path ++ "\t" ++ ctx.fs().sha256_file(path) ++ "\n"
    listing

/// Every module in the corpus's generated directories.
fn corpus_modules_hash(ctx: &ActionCtx, corpus: &Corpus) -> str:
    var listing = corpus_dir_listing(ctx, corpus.corpus_dir)
    for dir in corpus.extra_generated_dirs: listing = listing ++ corpus_dir_listing(ctx, dir)
    corpus_sha256_text(listing)

pub fn corpus_stamp_path(corpus: &Corpus) -> str: corpus.corpus_dir ++ "/corpus.stamp"

fn corpus_write_stamp(ctx: &ActionCtx, corpus: &Corpus) -> i32:
    let text = "# D112: written by promotion, never by hand. The migrator generation that\n# produced these modules (a hash of the migrator's sources) and a hash of\n# the modules; the integrity check compares the second.\nmigrated_by " ++ corpus_migrator_generation(ctx) ++ "\nmodules " ++ corpus_modules_hash(ctx, corpus) ++ "\n"
    if ctx.fs().write_text(corpus_stamp_path(corpus), text) != 0: return corpus_fail(ctx, "cannot write " ++ corpus_stamp_path(corpus))
    0

fn corpus_stamp_field(text: &str, key: &str) -> str:
    for line in text.split("\n"):
        if line.starts_with(key ++ " "): return line.slice(key.len() + 1, line.len())
    ""

/// `<stem>-integrity`: the corpus is what promotion wrote. No migration.
pub fn run_corpus_integrity_action(ctx: ActionCtx) -> i32:
    let owned = action_corpus(ctx)
    let corpus = &owned
    let stamp = corpus_stamp_path(corpus)
    if not ctx.fs().exists(stamp): return corpus_fail(ctx, corpus.name ++ ": no " ++ stamp ++ "; promotion writes it (D112)")
    let recorded = corpus_stamp_field(ctx.fs().read_text(stamp), "modules")
    let actual = corpus_modules_hash(&ctx, corpus)
    if recorded != actual:
        return corpus_fail(ctx, corpus.name ++ ": the corpus is not what promotion wrote (" ++ stamp ++ " records modules " ++ recorded ++ "; the tree hashes to " ++ actual ++ "). A corpus is never edited by hand (D112): restore it, or re-promote it for one of D112's three reasons")
    print(corpus.name ++ ": the corpus is what promotion wrote (migrated_by " ++ corpus_stamp_field(ctx.fs().read_text(stamp), "migrated_by") ++ ")")
    if ctx.fs().write_text(ctx.output(), "ok\n") != 0: return corpus_fail(ctx, "cannot write " ++ ctx.output())
    0

/// How the checked-in corpus differs from a fresh migration: one line per
/// module that differs, is missing or is extra. The migration is against
/// the C model (build/corpus.w, #2060), so it means the same on every host.
fn corpus_drift_lines(ctx: &ActionCtx, corpus: &Corpus) -> Vec[str]:
    let fs = ctx.fs()
    var lines: Vec[str] = Vec.new()
    let generated = corpus_scratch(ctx) ++ "/generated"
    if corpus_generate(ctx, corpus, generated) != 0:
        lines.push("  the fresh migration failed; see the log above")
        return lines
    let fresh = corpus_w_names(ctx, generated)
    let checked_in = corpus_w_names(ctx, corpus.corpus_dir)
    for name in fresh:
        if not checked_in.contains(name): lines.push("  would add: " ++ corpus.corpus_dir ++ "/" ++ name)
        else:
            let now = fs.read_text(corpus.corpus_dir ++ "/" ++ name)
            let next = fs.read_text(generated ++ "/" ++ name)
            if now != next: lines.push("  would change: " ++ corpus.corpus_dir ++ "/" ++ name ++ f" ({now.len()} -> {next.len()} bytes)")
    for name in checked_in:
        if not fresh.contains(name): lines.push("  would remove: " ++ corpus.corpus_dir ++ "/" ++ name)
    lines

/// `<stem>-drift-report` (nightly, never a gate): which modules a
/// re-promotion with today's migrator would change, and by how much.
pub fn run_corpus_drift_report_action(ctx: ActionCtx) -> i32:
    let owned = action_corpus(ctx)
    let lines = corpus_drift_lines(&ctx, &owned)
    var report = owned.name ++ f": {lines.len()} modules would change on re-promotion"
    for line in lines: report = report ++ "\n" ++ line
    print(report)
    if ctx.fs().write_text(ctx.output(), report ++ "\n") != 0: return corpus_fail(ctx, "cannot write " ++ ctx.output())
    0

/// `<stem>-stamp`: records the stamp for a corpus that is already today's
/// migrator output (the corpora that predate D112). It refuses a corpus a
/// fresh migration would change: that one moves only by promotion.
pub fn run_corpus_stamp_action(ctx: ActionCtx) -> i32:
    let owned = action_corpus(ctx)
    let corpus = &owned
    let lines = corpus_drift_lines(&ctx, corpus)
    if lines.len() > 0:
        var detail = ""
        for line in lines: detail = detail ++ "\n" ++ line
        return corpus_fail(ctx, corpus.name ++ ": not today's migrator output, so it is stamped only by promotion:" ++ detail)
    if corpus_write_stamp(&ctx, corpus) != 0: return 1
    print("stamped " ++ corpus_stamp_path(corpus))
    if ctx.fs().write_text(ctx.output(), "ok\n") != 0: return corpus_fail(ctx, "cannot write " ++ ctx.output())
    0

// ── the pipeline ────────────────────────────────────────────────

fn corpus_target(kind: BuildKind, corpus: &Corpus, suffix: &str, output: &str) -> Target:
    let name = corpus.stem ++ "-" ++ suffix
    var target = target_new(kind, name.clone(), "").output(output.clone())
    target = target.arg(corpus.name.clone())
    target.write_scope("out/tmp/action-scratch/" ++ name)

/// Every corpus module except the root as inputs (the root is the output
/// of `<stem>-bundle-root`, and the check reads it itself).
fn target_with_corpus_module_inputs(target: Target, ctx: &BuildCtx, corpus: &Corpus) -> Target:
    var out = target
    for path in ctx.fs().list_files(corpus.corpus_dir):
        if path.ends_with(".w") and not path.ends_with("/bundle.w"): out = out.input(path.clone())
    out

/// The generic pipeline: fetch, extract, prepare, migrate, check, promote,
/// the root tools, the drift lane, and the corpus's own lanes.
pub fn corpus_pipeline(out: Build, ctx: &BuildCtx, corpus: &Corpus, release_compiler: &str) -> Build:
    let up = corpus.upstream
    var graph = out.download(corpus.stem ++ "-download", Download {
        url: up.url.clone(), sha256: up.sha256.clone(), output_path: up.archive.clone(),
    })
    graph = graph.extract_tar_gz(corpus.stem ++ "-reference", up.archive.clone(), up.extracted.clone())

    var prepare = corpus_target(.Action, corpus, "prepare-reference", up.reference ++ "/.with-reference-ready")
    prepare.action = run_corpus_prepare_reference_action
    prepare = prepare.input(up.extracted.clone()).dep(corpus.stem ++ "-reference")
    prepare = prepare.write_scope(up.reference.clone())
    graph = graph.add_target(prepare)

    var migrate = corpus_target(.Action, corpus, "migrate", corpus_migrated_dir(corpus))
    migrate.action = run_corpus_migrate_action
    migrate = migrate.input(up.reference.clone()).dep(corpus.stem ++ "-prepare-reference")
    migrate = corpus_migrating_target(move migrate, release_compiler)
    graph = graph.add_target(migrate)

    var check = corpus_target(.Action, corpus, "check-generated", "out/gen/." ++ corpus.stem ++ "-check-generated-stamp")
    check.action = run_corpus_check_generated_action
    check = check.input(corpus_migrated_dir(corpus)).input(release_compiler.clone()).dep(corpus.stem ++ "-migrate").dep("build")
    graph = graph.add_target(check)

    var promote = corpus_target(.Action, corpus, "promote", corpus.corpus_dir.clone())
    promote.action = run_corpus_promote_action
    promote = promote.input(corpus_migrated_dir(corpus)).input(release_compiler.clone()).dep(corpus.stem ++ "-check-generated")
    for after in corpus.promote_after: promote = promote.dep(after.clone())
    graph = graph.add_target(promote)

    // A tool, not a producer: its output is a stamp, so the graph never runs
    // it to satisfy the root as an input of the bundle and check targets.
    var root = corpus_target(.Action, corpus, "bundle-root", "out/.build-state/" ++ corpus.stem ++ "-bundle-root.stamp")
    root.action = run_corpus_bundle_root_action
    root = root.write_scope(corpus.corpus_dir.clone()).write_scope("out/.build-state")
    root = target_with_corpus_module_inputs(move root, ctx, corpus)
    graph = graph.add_target(root)

    let plan = corpus_bundle_plan(ctx, corpus)
    var root_check = corpus_target(.Action, corpus, "bundle-root-check", "out/wo-drift/" ++ corpus.stem ++ "-bundle-root-check.stamp")
    root_check.action = run_corpus_bundle_root_check_action
    root_check = root_check.input(corpus.corpus_dir ++ "/bundle.w")
    root_check = target_with_corpus_module_inputs(move root_check, ctx, corpus)
    root_check = root_check.write_scope("out/wo-drift")
    graph = graph.add_target(root_check)
    graph = graph.add_target(wo_drift_target(ctx, &plan, release_compiler, "build", corpus.corpus_dir ++ "/" ++ corpus.drift_harness, corpus.drift_harness_arg))

    // D112: integrity (no migration) gates every battery; the drift report
    // is the nightly's; the stamp tool stamps a corpus that is already
    // today's migrator output.
    var integrity = corpus_target(.Action, corpus, "integrity", "out/corpus-integrity/" ++ corpus.stem ++ ".ok")
    integrity.action = run_corpus_integrity_action
    integrity = integrity.input(corpus_stamp_path(corpus))
    integrity = target_with_corpus_module_inputs(integrity, ctx, corpus)
    for dir in corpus.extra_generated_dirs: integrity = integrity.input(dir.clone())
    integrity = integrity.write_scope("out/corpus-integrity").allow_parallel()
    graph = graph.add_target(integrity)

    var drift = corpus_target(.Action, corpus, "drift-report", "out/corpus-drift/" ++ corpus.stem ++ ".txt")
    drift.action = run_corpus_drift_report_action
    drift = corpus_migrating_target(move drift, release_compiler)
    drift = drift.input(up.reference.clone()).input(corpus.corpus_dir ++ "/bundle.w")
    drift = target_with_corpus_module_inputs(move drift, ctx, corpus)
    drift = drift.dep(corpus.stem ++ "-prepare-reference")
    drift = drift.write_scope("out/corpus-drift").allow_parallel()
    graph = graph.add_target(drift)

    var stamp = corpus_target(.Action, corpus, "stamp", "out/corpus-stamp/" ++ corpus.stem ++ ".ok")
    stamp.action = run_corpus_stamp_action
    stamp = corpus_migrating_target(stamp, release_compiler)
    stamp = stamp.input(up.reference.clone()).input(corpus.corpus_dir ++ "/bundle.w")
    stamp = target_with_corpus_module_inputs(stamp, ctx, corpus)
    stamp = stamp.dep(corpus.stem ++ "-prepare-reference")
    stamp = stamp.write_scope("out/corpus-stamp").write_scope(corpus.corpus_dir.clone())
    graph = graph.add_target(stamp)

    corpus.lanes(move graph, ctx, corpus, release_compiler)

/// The `wo-drift` group: every corpus's root check and drift lane.
pub fn corpora_drift_group(ctx: &BuildCtx) -> Target:
    var group = target_new(.Group, "wo-drift", "")
    for i in 0..corpus_count():
        let corpus = corpus_at(i)
        let plan = corpus_bundle_plan(ctx, corpus)
        group = group.dep(corpus.stem ++ "-bundle-root-check")
        group = group.dep(wo_drift_target_name(&plan))
    group

/// `corpus-integrity-check` (the gate): every corpus is what promotion wrote.
pub fn corpora_integrity_group() -> Target:
    var group = target_new(.Group, "corpus-integrity-check", "")
    for i in 0..corpus_count(): group = group.dep(corpus_at(i).stem ++ "-integrity")
    group

/// `corpus-migrator-gate` (D112 amendment 1): every corpus migrated afresh
/// with this tree's migrator, type-checked with its harness, and its
/// upstream tests run on the fresh output. Nothing is promoted.
pub fn corpora_migrator_gate_group() -> Target:
    var group = target_new(.Group, "corpus-migrator-gate", "")
    for i in 0..corpus_count():
        let corpus = corpus_at(i)
        group = group.dep(corpus.stem ++ "-check-generated")
        for lane in corpus.fresh_test_lanes: group = group.dep(lane.clone())
    group

/// `corpus-drift-report` (nightly, informational): which corpora a
/// re-promotion would change, and by how much.
pub fn corpora_drift_report_group() -> Target:
    var group = target_new(.Group, "corpus-drift-report", "")
    for i in 0..corpus_count(): group = group.dep(corpus_at(i).stem ++ "-drift-report")
    group

/// The corpora lanes `:test` runs.
pub fn corpora_test_deps(target: Target) -> Target:
    var out = target
    for i in 0..corpus_count():
        let corpus = corpus_at(i)
        if corpus.test_lane.len() > 0: out = out.dep(corpus.test_lane.clone())
    out
