module build.corpus

use std.build
use std.sysinfo

// A migrated C corpus (docs/proposals/stdlib_sourcing_plan.md, docs/spec/toolchain/wo_bundles.md):
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
    // functions upstream declares in its own headers but never defines (the
    // migrated extern has no body anywhere; it links only while unreferenced)
    declared_externs: Vec[str],
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

pub fn corpus_abs(ctx: &ActionCtx, path: &str) -> str:
    if path.len() > 0 and path[0] == '/': return corpus_owned_text(path)
    ctx.project_info().project_root() ++ "/" ++ path

pub fn corpus_scratch(ctx: &ActionCtx) -> str: "out/tmp/action-scratch/" ++ ctx.target_name()

/// #2230: the provenance of what a corpus test ran. One line per binary —
/// `<sha256>  <path>` (the shasum format) — printed to the log and appended
/// to `<output>/provenance.txt`, so a stale or half-built binary (the
/// native runner's partial attempt before a 97 fallback, a bundle from an
/// older migration) is visible at the first failure, not after a bisect.
pub fn corpus_provenance(ctx: &ActionCtx, output: &str, path: &str) -> i32:
    let fs = ctx.fs()
    let abs = corpus_abs(ctx, path)
    // Build-layer code runs on the pinned seed: only the seed's str surface.
    let line = fs.sha256_file(abs) ++ "  " ++ path
    print(ctx.target_name() ++ " ran " ++ line)
    let record = output ++ "/provenance.txt"
    if fs.write_text(record, fs.read_text(record) ++ line ++ "\n") != 0: return corpus_fail(ctx, "could not write " ++ record)
    0

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

// ── the C model (#2060) ─────────────────────────────────────────
//
// A corpus is one set of modules for every target: std.libc carries its
// libc calls everywhere, and the bundle is built from the same bytes on
// each host. So its migration is a function of the upstream source, the
// migrator and one C model — a target and that target's libc headers —
// never of the host that runs it: migrated for the host, a Linux run takes
// glibc's `#if` branches and macro values (zlib's ioapi.c calls fopen64)
// and a Windows run mingw-w64's, and no two hosts agree. The model is the
// one the corpora were promoted under: macOS on arm64, against the darwin
// headers of the pinned Zig source (build/sdk.w), which every host can
// generate. On macOS that tree is the darwin sysroot the compiler embeds;
// elsewhere `corpus-c-model` writes the same headers.
// The triple names its macOS version: left to clang it is the migrating
// Mac's own OS version, and off macOS none at all (the darwin headers then
// leave _FORTIFY_SOURCE off and <string.h> declares another memset).
pub fn corpus_c_model_target() -> str: "arm64-apple-macosx11.0"
pub fn corpus_c_model_dir() -> str: if os() == "Macos": "out/gen/darwin-sysroot" else: "out/gen/corpus-c-model"
pub fn corpus_c_model_stamp() -> str: if os() == "Macos": "out/gen/darwin-sysroot.pack" else: "out/gen/corpus-c-model.ready"
pub fn corpus_c_model_dep() -> str: if os() == "Macos": "darwin-sysroot" else: "corpus-c-model"

/// A target that migrates a corpus: the migrator is this tree's release
/// compiler, run as a process against the C model.
pub fn corpus_migrating_target(target: Target, release_compiler: &str) -> Target:
    var out = target.arg("migrator=" ++ release_compiler)
    out = out.input(corpus_owned_text(release_compiler)).input(corpus_c_model_stamp())
    out.dep("build").dep(corpus_c_model_dep())

/// Runs one migration. A target that names its `migrator=` (every corpus
/// migration: corpus_migrating_target) runs that compiler as a process
/// against the C model. One that names none (pcre2-migrate-smoke, a test of
/// the driver's migrator) runs a migrate workspace in the build driver's own
/// compiler, for the host.
pub fn corpus_run_migration(ctx: &ActionCtx, label: &str, options: MigrateOptions) -> i32:
    let migrator = corpus_migrator_arg(ctx)
    if migrator.len() > 0: return corpus_run_migration_process(ctx, label, migrator, &options)
    let workspace = ctx.create_workspace(label)
    var compiler_options = workspace.options()
    compiler_options.prelude_mode = PreludeMode.None
    workspace.set_options(compiler_options)
    workspace.set_migrate_options(options)
    let result = workspace.compile()
    if result.rc != 0: return corpus_fail(ctx, label ++ f" exited {result.rc}")
    0

/// The compiler an action's `migrator=<path>` arg names ("" = none: the
/// migration runs in the driver, as above). A corpus's migrate target and its
/// drift check (#1905) name the same one, this tree's release compiler.
pub fn corpus_migrator_arg(ctx: &ActionCtx) -> str:
    for arg in ctx.args():
        if arg.starts_with("migrator="): return arg.slice("migrator=".len(), arg.len())
    ""

/// `<compiler> migrate` with exactly the options a workspace migration
/// takes: the CLI and the workspace both set the migrator's options and call
/// migrate_c_directory (or migrate_c_file), and a `--no-prelude` CLI run is
/// the workspace's PreludeMode.None.
pub fn corpus_migrate_argv(ctx: &ActionCtx, compiler: &str, options: &MigrateOptions) -> Vec[str]:
    var argv: Vec[str] = Vec.new()
    argv.push(corpus_abs(ctx, compiler))
    argv.push("migrate")
    argv.push(corpus_abs(ctx, options.source_path))
    argv.push("-o")
    argv.push(corpus_abs(ctx, options.output_path))
    argv.push("--c-target")
    argv.push(corpus_c_model_target())
    argv.push("--c-sysroot")
    argv.push(corpus_abs(ctx, corpus_c_model_dir()))
    for path in options.include_paths:
        argv.push("-I")
        argv.push(corpus_abs(ctx, path))
    for header in options.forced_includes:
        argv.push("-include")
        argv.push(header.clone())
    for define in options.defines:
        argv.push("-D")
        argv.push(define.clone())
    for exclude in options.exclude_basenames:
        argv.push("--exclude")
        argv.push(exclude.clone())
    argv.push("--no-prelude")
    if options.no_c_export: argv.push("--no-c-export")
    if options.c_export_functions: argv.push("--c-export-functions")
    if options.convert_goto_to_structured: argv.push("--convert-goto-to-structured")
    if options.block_style == 2: argv.push("--prefer-brace")
    if options.block_style == 0: argv.push("--prefer-colon")
    argv.push("--width-slice")
    argv.push(f"{options.width_slice}")
    if options.shared_defs.len() > 0:
        argv.push("--shared-defs")
        argv.push(options.shared_defs.clone())
    if options.migrate_one.len() > 0:
        argv.push("--migrate-one")
        argv.push(options.migrate_one.clone())
    if options.shared_fragment.len() > 0:
        argv.push("--shared-fragment")
        argv.push(corpus_abs(ctx, options.shared_fragment))
    argv

fn corpus_run_migration_process(ctx: &ActionCtx, label: &str, compiler: &str, options: &MigrateOptions) -> i32:
    if options.check_mode or options.diff_mode or options.stats_mode or options.ir_roundtrip:
        return corpus_fail(ctx, label ++ ": the migrate CLI has no check/diff/stats/ir-roundtrip mode for a corpus migration")
    let stdout = corpus_abs(ctx, corpus_scratch(ctx) ++ "/" ++ label ++ ".stdout")
    let stderr = corpus_abs(ctx, corpus_scratch(ctx) ++ "/" ++ label ++ ".stderr")
    let result = ctx.process_runner().run_capture_cwd(corpus_migrate_argv(ctx, compiler, options), stdout, stderr.clone(), 1200000, corpus_abs(ctx, "."))
    if result.rc != 0: return corpus_fail(ctx, label ++ f": `migrate` exited {result.rc}; see " ++ stderr)
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

/// Type-checks the generated bundle root, which imports every module: a
/// module no harness program reaches (minizip's mztools) is otherwise first
/// compiled by the bundle build, after promotion replaced the corpus.
/// `compiler` checks them as the bundle build compiles them: the prelude
/// off, and the corpus read from these sources (`--bundle-corpus`), never from
/// the bundle interface that compiler embeds, which predates the migration.
pub fn corpus_check_every_module(ctx: &ActionCtx, corpus: &Corpus, generated: &str, compiler: &str) -> i32:
    let tree = corpus_scratch(ctx) ++ "/check"
    let modules = tree ++ "/lib/" ++ corpus.corpus_rel
    if corpus_reset_dir(ctx, tree) != 0: return 1
    if corpus_copy_w_files(ctx, generated, modules) != 0: return 1
    // Pushed, not a literal: the pinned seed frees a literal's moved
    // temporaries (#1122).
    var argv: Vec[str] = Vec.new()
    argv.push(corpus_abs(ctx, compiler))
    argv.push("check")
    argv.push(corpus_abs(ctx, modules ++ "/bundle.w"))
    argv.push("--no-prelude")
    argv.push("--bundle-corpus")
    argv.push(corpus.corpus_rel.clone())
    let stdout = corpus_abs(ctx, tree ++ "/check.stdout")
    let stderr = corpus_abs(ctx, tree ++ "/check.stderr")
    let checked = ctx.process_runner().run_capture_cwd(argv, stdout, stderr.clone(), 600000, corpus_abs(ctx, "."))
    if checked.rc != 0: return corpus_fail(ctx, corpus.name ++ f" generated modules do not type-check (exit {checked.rc}); see " ++ stderr)
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
            eprint("error: " ++ corpus.name ++ " generated source contains a forbidden c_export attribute in " ++ path)
            errors = errors + 1
        if text.contains("// Bail:") or text.contains("[MIGRATOR_UNTRANSLATED]"):
            eprint("error: " ++ corpus.name ++ " generated source contains untranslatable migrator output in " ++ path)
            errors = errors + 1
    if modules < corpus.module_floor:
        return corpus_fail(ctx, f"only {modules} generated .w files under " ++ generated ++ f"; expected at least {corpus.module_floor}")
    errors

/// The externs a migrated module may declare: the migrator preamble's ctype,
/// libm and with_* runtime set (ci_migrate_preamble_text, src/CiMigrate.w).
/// Everything else a corpus reaches comes through std.libc or its own
/// definitions, so the bundle links on every target (Eric, 2026-09-15).
fn corpus_permitted_externs() -> str:
    "|strlen|strcmp|strncmp|strchr|memchr|isalpha|isdigit|isalnum|isspace|isupper|islower|isxdigit|isprint|isgraph|ispunct|iscntrl|tolower|toupper|" ++
    "sqrt|pow|floor|ceil|round|sin|cos|tan|log|log10|exp|fabs|fmod|asin|acos|atan|atan2|abort|" ++
    "with_clz|with_ctz|with_popcount|with_bswap16|with_bswap32|with_bswap64|with_clzl|with_clzll|with_ctzl|with_ctzll|with_abs|" ++
    "with_alloc|with_alloc_zeroed|with_realloc|with_free|with_memcpy|with_memmove|with_memset|with_memcmp|"

/// Host-only symbols std.libc no longer exports; a reference in generated
/// source means the migrator emitted the host's spelling instead of the model.
fn corpus_retired_host_symbols() -> Vec[str]:
    ["__stderrp", "__stdoutp", "__stdinp", "__error(", "__errno_location(", "_errno(", "__acrt_iob_func(", "_fileno(", "_isatty("]

// Not `str.trim`: this runs under the comptime evaluator when the action
// falls back to it (a verify hook that intercepts the workspace), and the
// evaluator has no trim yet.
fn corpus_trim(text: &str) -> str:
    var start = 0
    var end = text.len() as i32
    while start < end and (text[start] == ' ' or text[start] == '\t' or text[start] == '\r'):
        start = start + 1
    while end > start and (text[end - 1] == ' ' or text[end - 1] == '\t' or text[end - 1] == '\r'):
        end = end - 1
    text.slice(start as i64, end as i64)

fn corpus_ident_prefix(text: &str) -> str:
    var end = 0
    while end < text.len() as i32:
        let ch = text[end]
        let ident = (ch >= 'a' and ch <= 'z') or (ch >= 'A' and ch <= 'Z') or (ch >= '0' and ch <= '9') or ch == '_'
        if not ident: break
        end = end + 1
    text.slice(0, end as i64)

/// The generated tree references no foreign symbol: every extern it declares
/// is a preamble name or one of its own definitions, no variable is
/// declared extern, and no retired host spelling survives. Returns the
/// error count.
pub fn corpus_reject_foreign_symbols(ctx: &ActionCtx, corpus: &Corpus, generated: &str) -> i32:
    let fs = ctx.fs()
    var permitted = corpus_permitted_externs()
    for i in 0..corpus.declared_externs.len() as i32: permitted = permitted ++ corpus.declared_externs[i] ++ "|"
    var defined = "|"
    var errors = 0
    let files = fs.list_files(generated)
    for i in 0..files.len() as i32:
        let path = files[i]
        if not path.ends_with(".w"): continue
        for line in fs.read_text(path).split("\n"):
            let l = corpus_trim(line)
            for head in ["pub unsafe fn ", "pub fn ", "unsafe fn ", "fn "]:
                if l.starts_with(head):
                    defined = defined ++ corpus_ident_prefix(l.slice(head.len(), l.len())) ++ "|"
                    break
    for i in 0..files.len() as i32:
        let path = files[i]
        if not path.ends_with(".w"): continue
        let text = fs.read_text(path)
        var nr = 0
        for line in text.split("\n"):
            nr = nr + 1
            let l = corpus_trim(line)
            if l.starts_with("extern var ") or l.starts_with("pub extern var "):
                eprint("error: " ++ corpus.name ++ f" generated source declares a foreign variable at {path}:{nr}: " ++ l)
                errors = errors + 1
            else if l.starts_with("extern fn ") or l.starts_with("pub extern fn "):
                let head_len = if l.starts_with("pub "): 14 else: 10
                let name = corpus_ident_prefix(l.slice(head_len, l.len()))
                if not permitted.contains("|" ++ name ++ "|") and not defined.contains("|" ++ name ++ "|"):
                    eprint("error: " ++ corpus.name ++ f" generated source declares the foreign symbol '" ++ name ++ f"' at {path}:{nr}; std.libc models the C surface, extend it instead")
                    errors = errors + 1
        for retired in corpus_retired_host_symbols():
            if text.contains(retired):
                eprint("error: " ++ corpus.name ++ " generated source references the host-only symbol '" ++ retired ++ "' in " ++ path ++ "; the migrator must emit the std.libc model")
                errors = errors + 1
    errors

/// The .wo bundle root (docs/spec/toolchain/wo_bundles.md "Root"): one `use` per corpus
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
    var text = "// " ++ corpus.corpus_dir ++ "/bundle.w — the " ++ corpus.name ++ " .wo bundle root (docs/spec/toolchain/wo_bundles.md).\n"
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
