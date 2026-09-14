module build.corpora

use std.build
use build.corpus
use build.wo
use build.pcre2
use build.zlib
use build.c_algorithms
use build.tommyds

// The corpus registry (docs/wo_bundles.md, docs/stdlib_sourcing_plan.md):
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

/// The corpus packages are internal modules of the compiler (the spec
/// inventory takes them as `internal-module=` args).
pub fn corpora_internal_module_args(target: Target) -> Target:
    var out = target
    for i in 0..corpus_count(): out = out.arg("internal-module=" ++ corpus_at(i).package)
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
    let prepare = corpus.prepare_reference
    if prepare(&ctx, corpus, &reference) != 0: return 1
    if ctx.fs().write_text(ctx.output(), "ok\n") != 0: return corpus_fail(ctx, "cannot write " ++ ctx.output())
    0

/// Stage, migrate, finish, write the root, record the upstream, publish.
pub fn run_corpus_migrate_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let owned = action_corpus(ctx)
    let corpus = &owned
    let reference = corpus.upstream.reference.clone()
    let output = ctx.output()
    let source = corpus_scratch(ctx) ++ "/source"
    let generated = corpus_scratch(ctx) ++ "/generated"
    if corpus_reset_dir(ctx, source) != 0 or corpus_reset_dir(ctx, generated) != 0: return 1
    let stage = corpus.stage
    if stage(&ctx, corpus, &reference, &source) != 0: return 1
    let migrate = corpus.migrate
    if migrate(&ctx, corpus, &source, &generated) != 0: return 1
    let finish = corpus.finish_generated
    if finish(&ctx, corpus, &generated) != 0: return 1
    if corpus_write_bundle_root(ctx, corpus, generated) != 0: return 1
    if corpus.license.len() > 0:
        if corpus_copy(ctx, reference ++ "/" ++ corpus.license, generated ++ "/" ++ corpus.license) != 0: return 1
    if fs.write_text(generated ++ "/UPSTREAM", corpus.upstream.revision ++ "\nsha256=" ++ corpus.upstream.sha256 ++ "\n") != 0: return 1
    if fs.exists(output) and fs.remove_tree(output) != 0: return corpus_fail(ctx, "cannot replace " ++ output)
    if fs.rename(generated, output) != 0: return corpus_fail(ctx, "cannot publish " ++ output)
    print("migrated " ++ corpus.name ++ f": {corpus_count_w_files(ctx, output)} modules in " ++ corpus_abs(ctx, output))
    0

fn corpus_check_generated(ctx: &ActionCtx, corpus: &Corpus, generated: &str) -> i32:
    if corpus_reject_bad_output(ctx, corpus, generated) != 0: return 1
    let verify = corpus.verify_generated
    verify(ctx, corpus, generated)

pub fn run_corpus_check_generated_action(ctx: ActionCtx) -> i32:
    let owned = action_corpus(ctx)
    if corpus_check_generated(ctx, &owned, ctx.inputs()[0]) != 0: return 1
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
    if corpus_check_generated(ctx, corpus, generated) != 0: return 1
    if fs.mkdir_all(destination) != 0: return corpus_fail(ctx, "cannot create " ++ destination)
    for path in fs.list_files(destination):
        if path.ends_with(".w") and fs.remove_file(path) != 0: return corpus_fail(ctx, "cannot remove " ++ path)
    var copied = 0
    for path in fs.list_files(generated):
        if not path.ends_with(".w"): continue
        if corpus_copy(ctx, path, destination ++ "/" ++ corpus_basename(path)) != 0: return 1
        copied = copied + 1
    print(f"promoted {copied} generated " ++ corpus.name ++ " modules into " ++ corpus_abs(ctx, destination))
    0

/// Regenerates the promoted root from the corpus listing (the tool for a
/// root that predates the generator's current text).
pub fn run_corpus_bundle_root_action(ctx: ActionCtx) -> i32:
    let owned = action_corpus(ctx)
    corpus_write_bundle_root(ctx, &owned, owned.corpus_dir)

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
    graph = graph.add_target(migrate)

    var check = corpus_target(.Action, corpus, "check-generated", "out/gen/." ++ corpus.stem ++ "-check-generated-stamp")
    check.action = run_corpus_check_generated_action
    check = check.input(corpus_migrated_dir(corpus)).dep(corpus.stem ++ "-migrate")
    graph = graph.add_target(check)

    var promote = corpus_target(.Action, corpus, "promote", corpus.corpus_dir.clone())
    promote.action = run_corpus_promote_action
    promote = promote.input(corpus_migrated_dir(corpus)).dep(corpus.stem ++ "-check-generated")
    for after in corpus.promote_after: promote = promote.dep(after.clone())
    graph = graph.add_target(promote)

    var root = corpus_target(.Action, corpus, "bundle-root", corpus.corpus_dir ++ "/bundle.w")
    root.action = run_corpus_bundle_root_action
    root = root.write_scope(corpus.corpus_dir.clone())
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

    let lanes = corpus.lanes
    lanes(move graph, ctx, corpus, release_compiler)

/// The `wo-drift` group: every corpus's root check and drift lane.
pub fn corpora_drift_group(ctx: &BuildCtx) -> Target:
    var group = target_new(.Group, "wo-drift", "")
    for i in 0..corpus_count():
        let corpus = corpus_at(i)
        let plan = corpus_bundle_plan(ctx, corpus)
        group = group.dep(corpus.stem ++ "-bundle-root-check")
        group = group.dep(wo_drift_target_name(&plan))
    group

/// The corpora lanes `:test` runs.
pub fn corpora_test_deps(target: Target) -> Target:
    var out = target
    for i in 0..corpus_count():
        let corpus = corpus_at(i)
        if corpus.test_lane.len() > 0: out = out.dep(corpus.test_lane.clone())
    out
