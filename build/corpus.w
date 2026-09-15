module build.corpus

use std.build

// A migrated C corpus (docs/stdlib_sourcing_plan.md, docs/wo_bundles.md):
// the facts about one upstream library and the few hooks its pipeline
// needs. Everything structurally shared — fetching, staging, migration,
// the bundle root, the generated-tree checks, promotion, the .wo bundle,
// embedding, source exclusion, the drift and root-check lanes, stage and
// cross-target and release wiring — is generic (build/corpora.w, build/wo.w
// and build.w iterate the registry); a corpus description holds only what
// is true of that corpus. A hook is an explicit function, never a flag: the
// common path stays strong and an unusual library gets one small hook.

fn corpus_owned_text(s: &str): s ++ ""

/// A pinned upstream tarball and where its tree lives under out/.
pub type Upstream {
    url: str,
    sha256: str,
    // what the corpus's UPSTREAM file records (a revision or a release name)
    revision: str,
    // the fetched archive
    archive: str,
    // the directory the archive extracts under
    extracted: str,
    // the extracted tree root (under `extracted`)
    reference: str,
}

pub type Corpus ephemeral {
    // bundle name and the out/<name>_* stem: c_algorithms
    name: str,
    // target-name stem: <stem>-migrate, -check-generated, -promote,
    // -bundle-root, -bundle-root-check, -test: c-algorithms
    stem: str,
    // the migrated modules' package: std.c_algorithms
    package: str,
    // the `--bundle-corpus` spelling under the embedded std tree: std/c_algorithms
    corpus_rel: str,
    // the tree directory: lib/std/c_algorithms
    corpus_dir: str,
    upstream: Upstream,
    // the license file in the reference tree, copied beside the migration ("" = none)
    license: str,
    // modules that ride in the corpus but never in the bundle root (the harness)
    harness: Vec[str],
    // the corpus module the drift lane builds against both objects, and its argument
    drift_harness: str,
    drift_harness_arg: str,
    // the least number of generated modules a migration must produce
    module_floor: i32,
    // preprocessor defines and excluded basenames for the directory migration
    defines: Vec[str],
    excludes: Vec[str],
    // lane targets a promote waits for (the corpus's own tests)
    promote_after: Vec[str],
    // the lane `:test` runs ("" = none)
    test_lane: str,
    // ── hooks ────────────────────────────────────────────────────
    // adjust the extracted reference tree (pcre2 generates config.h)
    prepare_reference: fn(&ActionCtx, &Corpus, &str) -> i32,
    // copy the migration's inputs from the reference tree into the flat source dir
    stage: fn(&ActionCtx, &Corpus, &str, &str) -> i32,
    // translate the staged sources into the generated dir
    migrate: fn(&ActionCtx, &Corpus, &str, &str) -> i32,
    // fix up the generated tree before the root is written
    finish_generated: fn(&ActionCtx, &Corpus, &str) -> i32,
    // extra checks over the generated tree (check-generated and promote)
    verify_generated: fn(&ActionCtx, &Corpus, &str) -> i32,
    // the corpus's test lanes; receives the release compiler path
    lanes: fn(Build, &BuildCtx, &Corpus, &str) -> Build,
}

/// A GitHub tarball pinned to a revision: codeload's `<repo>-<revision>` root.
pub fn upstream_github(name: &str, repo: &str, revision: &str, sha256: &str) -> Upstream:
    let extracted = "out/" ++ name ++ "_reference/extracted"
    let short = repo.split("/")
    Upstream {
        url: "https://codeload.github.com/" ++ repo ++ "/tar.gz/" ++ revision,
        sha256: corpus_owned_text(sha256), revision: corpus_owned_text(revision),
        archive: "out/" ++ name ++ "_reference/" ++ short[short.len() - 1] ++ ".tar.gz",
        extracted: extracted.clone(), reference: extracted ++ "/" ++ short[short.len() - 1] ++ "-" ++ revision,
    }

/// A release tarball whose root directory is the release name.
pub fn upstream_release(name: &str, release: &str, url: &str, sha256: &str) -> Upstream:
    let extracted = "out/" ++ name ++ "_reference"
    Upstream {
        url: corpus_owned_text(url), sha256: corpus_owned_text(sha256), revision: corpus_owned_text(release),
        archive: extracted ++ "/" ++ release ++ ".tar.gz",
        extracted: extracted.clone(), reference: extracted ++ "/" ++ release,
    }

// ── hook defaults ───────────────────────────────────────────────

pub fn corpus_no_prepare(ctx: &ActionCtx, corpus: &Corpus, reference: &str) -> i32: 0
pub fn corpus_no_finish(ctx: &ActionCtx, corpus: &Corpus, generated: &str) -> i32: 0
pub fn corpus_no_verify(ctx: &ActionCtx, corpus: &Corpus, generated: &str) -> i32: 0
pub fn corpus_no_lanes(out: Build, ctx: &BuildCtx, corpus: &Corpus, release_compiler: &str) -> Build: out

// ── shared helpers ──────────────────────────────────────────────

pub fn corpus_fail(ctx: &ActionCtx, message: &str) -> i32:
    ctx.diagnostics().error(ctx.target_name() ++ ": " ++ message)
    1

pub fn corpus_abs(ctx: &ActionCtx, path: &str) -> str:
    if path.len() > 0 and path[0] == '/': return corpus_owned_text(path)
    ctx.project_info().project_root() ++ "/" ++ path

pub fn corpus_scratch(ctx: &ActionCtx) -> str: "out/tmp/action-scratch/" ++ ctx.target_name()

pub fn corpus_basename(path: &str) -> str:
    let parts = path.split("/")
    parts[parts.len() - 1].clone()

pub fn corpus_module_name(path: &str) -> str:
    let base = corpus_basename(path)
    for i in 0..base.len():
        if base[i] == '.': return base.slice(0, i)
    base

pub fn corpus_reset_dir(ctx: &ActionCtx, path: &str) -> i32:
    let fs = ctx.fs()
    if fs.exists(path) and fs.remove_tree(path) != 0: return corpus_fail(ctx, "cannot remove " ++ path)
    if fs.mkdir_all(path) != 0: return corpus_fail(ctx, "cannot create " ++ path)
    0

pub fn corpus_copy(ctx: &ActionCtx, source: &str, destination: &str) -> i32:
    if ctx.fs().copy_file(source, destination) != 0:
        return corpus_fail(ctx, "cannot copy " ++ source ++ " to " ++ destination)
    0

/// Copies every .w file of `source_dir` flat into `destination`.
pub fn corpus_copy_w_files(ctx: &ActionCtx, source_dir: &str, destination: &str) -> i32:
    if ctx.fs().mkdir_all(destination) != 0: return corpus_fail(ctx, "cannot create " ++ destination)
    for path in ctx.fs().list_files(source_dir):
        if not path.ends_with(".w"): continue
        if corpus_copy(ctx, path, destination ++ "/" ++ corpus_basename(path)) != 0: return 1
    0

pub fn corpus_count_w_files(ctx: &ActionCtx, dir: &str) -> i32:
    var count = 0
    for path in ctx.fs().list_files(dir):
        if path.ends_with(".w"): count = count + 1
    count

// Bytewise order. Spelled as a byte loop, not `a < b`: the pinned seed's
// comptime evaluator (the linux-aarch64 asset) does not order strings.
fn corpus_str_less(a: &str, b: &str) -> bool:
    let min_len = if a.len() < b.len(): a.len() else: b.len()
    for i in 0..min_len as i32:
        if a[i] != b[i]: return (a[i] as i32) < (b[i] as i32)
    a.len() < b.len()

pub fn corpus_sorted(items: Vec[str]) -> Vec[str]:
    var sorted: Vec[str] = Vec.new()
    for item in items:
        var placed = false
        var next: Vec[str] = Vec.new()
        for existing in sorted:
            if not placed and corpus_str_less(item, existing):
                next.push(item.clone())
                placed = true
            next.push(existing.clone())
        if not placed: next.push(item.clone())
        sorted = next
    sorted

pub fn corpus_is_harness(corpus: &Corpus, name: &str) -> bool:
    for harness in corpus.harness:
        if name == harness: return true
    false

/// The migration every corpus runs: one directory, prelude-free output
/// (the .wo build compiles it --no-prelude, so its defs carry c_void and the
/// unreachable shim), no foreign ABI surface, one shared definitions module.
pub fn corpus_migrate_options(corpus: &Corpus, source: &str, output: &str) -> MigrateOptions:
    var defines: Vec[str] = Vec.new()
    for define in corpus.defines: defines.push(define.clone())
    var excludes: Vec[str] = Vec.new()
    for exclude in corpus.excludes: excludes.push(exclude.clone())
    MigrateOptions {
        source_path: corpus_owned_text(source), output_path: corpus_owned_text(output),
        include_paths: [corpus_owned_text(source)], forced_includes: Vec.new(),
        defines: defines, exclude_basenames: excludes, check_mode: false,
        diff_mode: false, stats_mode: false, no_c_export: true,
        c_export_functions: false, convert_goto_to_structured: false,
        block_style: 2, width_slice: 8, shared_defs: corpus.package ++ ".defs",
        migrate_one: "", shared_fragment: "", ir_roundtrip: false,
    }

/// Runs one migration workspace. A migration runs in the build driver's own
/// compiler (a migrate workspace is driver comptime evaluation), so
/// re-migrating needs a tree compiler as the driver:
/// `WITH=out/release/bin/with out/release/bin/with build :<stem>-promote`.
/// The battery never migrates; it compiles the checked-in output.
pub fn corpus_run_migration(ctx: &ActionCtx, label: &str, options: MigrateOptions) -> i32:
    let workspace = ctx.create_workspace(label)
    var compiler_options = workspace.options()
    compiler_options.prelude_mode = PreludeMode.None
    workspace.set_options(compiler_options)
    workspace.set_migrate_options(options)
    let result = workspace.compile()
    if result.rc != 0: return corpus_fail(ctx, label ++ f" exited {result.rc}")
    0

/// The default migrate hook: the staged directory, whole.
pub fn corpus_migrate_directory(ctx: &ActionCtx, corpus: &Corpus, source: &str, generated: &str) -> i32:
    corpus_run_migration(ctx, corpus.stem ++ "-corpus", corpus_migrate_options(corpus, source, generated))

/// Compiles one With source to a binary with the driver's compiler.
pub fn corpus_compile_binary(ctx: &ActionCtx, label: &str, source: &str, output: &str) -> i32:
    let workspace = ctx.create_workspace(label)
    workspace.add_file(source)
    var options = workspace.options()
    options.output_path = corpus_owned_text(output)
    workspace.set_options(options)
    let result = workspace.compile()
    if result.rc != 0: return corpus_fail(ctx, label ++ f" exited {result.rc}")
    if not ctx.fs().exists(output): return corpus_fail(ctx, label ++ " did not produce " ++ output)
    0

/// The generated tree carries no foreign ABI surface and no untranslated
/// residue (No Silent Fallbacks); a migration that lost modules fails the
/// floor rather than promoting a partial corpus. Returns the error count.
pub fn corpus_reject_bad_output(ctx: &ActionCtx, corpus: &Corpus, generated: &str) -> i32:
    let fs = ctx.fs()
    var errors = 0
    var modules = 0
    for path in fs.list_files(generated):
        if not path.ends_with(".w"): continue
        modules = modules + 1
        let text = fs.read_text(path)
        if text.contains("@[c_export("):
            ctx.diagnostics().error(corpus.name ++ " generated source contains a forbidden c_export attribute in " ++ path)
            errors = errors + 1
        if text.contains("// Bail:") or text.contains("[MIGRATOR_UNTRANSLATED]"):
            ctx.diagnostics().error(corpus.name ++ " generated source contains untranslatable migrator output in " ++ path)
            errors = errors + 1
    if modules < corpus.module_floor:
        return corpus_fail(ctx, f"only {modules} generated .w files under " ++ generated ++ f"; expected at least {corpus.module_floor}")
    errors

/// The .wo bundle root (docs/wo_bundles.md "Root"): one `use` per corpus
/// module, bytewise by name, so the bundle build reaches every module. The
/// text is a pure function of the module listing; <stem>-bundle-root-check
/// checks the promoted root against it.
pub fn corpus_bundle_root_text(corpus: &Corpus, module_paths: &Vec[str]) -> str:
    var names: Vec[str] = Vec.new()
    for path in module_paths:
        if not path.ends_with(".w"): continue
        let name = corpus_module_name(path)
        if name == "bundle" or corpus_is_harness(corpus, name): continue
        names.push(name)
    var harness = ""
    for excluded in corpus.harness:
        harness = harness ++ (if harness.len() > 0: ", " else: "") ++ excluded
    var text = "// " ++ corpus.corpus_dir ++ "/bundle.w — the " ++ corpus.name ++ " .wo bundle root (docs/wo_bundles.md).\n"
    text = text ++ "// Written by build/corpora.w (" ++ corpus.stem ++ "-migrate) from the migrated module list:\n"
    text = text ++ "// one `use` per corpus module"
    if harness.len() > 0: text = text ++ "; the harness (" ++ harness ++ ") is excluded"
    text = text ++ ".\n"
    for name in corpus_sorted(move names): text = text ++ "use " ++ corpus.package ++ "." ++ name ++ "\n"
    text

/// Writes the root into `dir` (idempotent: an identical root is left alone).
pub fn corpus_write_bundle_root(ctx: &ActionCtx, corpus: &Corpus, dir: &str) -> i32:
    let fs = ctx.fs()
    let path = dir ++ "/bundle.w"
    let text = corpus_bundle_root_text(corpus, fs.list_files(dir))
    if fs.exists(path) and fs.read_text(path) == text: return 0
    if fs.write_text(path, text) != 0: return corpus_fail(ctx, "cannot write the bundle root " ++ path)
    0
