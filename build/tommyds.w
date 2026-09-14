module build.tommyds

use std.build

// TommyDS v3.0 (amadvance/tommyds), BSD-2-Clause (its LICENSE ships in the
// corpus). Phase 2 of docs/stdlib_sourcing_plan.md.
const TOMMY_REVISION = "1f3727fc89174902c48e3933ac4610cb7fb13f4a"
const TOMMY_SHA256 = "cf2036f73af8a5e20e50b42d36352ec932d6eee7b7e847bebeef2efd296385d3"
const TOMMY_PACKAGE = "std.tommyds"
const TOMMY_CORPUS_DIR = "lib/std/tommyds"

// Upstream compiles tommy.c, which #includes every other .c, as one unit;
// the corpus migrates the units themselves so each structure is a module.
fn tommy_modules() -> Vec[str]:
    ["tommyalloc", "tommyarray", "tommyarrayblk", "tommyarrayblkof",
     "tommyarrayof", "tommyhash", "tommyhashdyn", "tommyhashlin",
     "tommyhashtbl", "tommylist", "tommytree", "tommytrie", "tommytrieinp"]

fn tommy_headers() -> Vec[str]: ["tommy", "tommychain", "tommytypes"]

// Upstream's check program is the corpus's test: it rides in the promoted
// corpus as the wo-drift harness and the corpora lane's program, never in
// the bundle root.
// (`check` collides with the prelude name, so the migrator spells the module check_.)
fn tommy_is_harness(name: &str) -> bool: name == "check_"

fn tommy_fail(ctx: &ActionCtx, message: &str):
    ctx.diagnostics().error(ctx.target_name() ++ ": " ++ message)
    1

fn tommy_abs(ctx: &ActionCtx, path: &str): ctx.project_info().project_root() ++ "/" ++ path
fn tommy_scratch(ctx: &ActionCtx): "out/tmp/action-scratch/" ++ ctx.target_name()

fn tommy_basename(path: &str) -> str:
    let parts = path.split("/")
    parts[parts.len() - 1].clone()

fn tommy_module_name(path: &str) -> str:
    let base = tommy_basename(path)
    for i in 0..base.len():
        if base[i] == '.': return base.slice(0, i)
    base

fn tommy_reset(ctx: &ActionCtx, path: &str):
    let fs = ctx.fs()
    if fs.exists(path) and fs.remove_tree(path) != 0:
        return tommy_fail(ctx, "cannot remove " ++ path)
    if fs.mkdir_all(path) != 0: return tommy_fail(ctx, "cannot create " ++ path)
    0

fn tommy_copy(ctx: &ActionCtx, source: &str, destination: &str):
    if ctx.fs().copy_file(source, destination) != 0:
        return tommy_fail(ctx, "cannot copy " ++ source ++ " to " ++ destination)
    0

fn tommy_options(source: &str, output: &str) -> MigrateOptions:
    MigrateOptions {
        source_path: source.clone(), output_path: output.clone(),
        include_paths: [source.clone()], forced_includes: Vec.new(),
        defines: Vec.new(), exclude_basenames: Vec.new(), check_mode: false,
        diff_mode: false, stats_mode: false, no_c_export: true,
        c_export_functions: false, convert_goto_to_structured: false,
        block_style: 2, width_slice: 8, shared_defs: TOMMY_PACKAGE ++ ".defs",
        migrate_one: "", shared_fragment: "", ir_roundtrip: false,
    }

// A migration runs in the build driver's own compiler; re-migrating needs a
// tree compiler as the driver (`WITH=out/release/bin/with out/release/bin/with
// build :tommyds-promote`). The battery never migrates.
fn tommy_migrate(ctx: &ActionCtx, label: &str, options: MigrateOptions):
    let workspace = ctx.create_workspace(label)
    var compiler_options = workspace.options()
    compiler_options.prelude_mode = PreludeMode.None
    workspace.set_options(compiler_options)
    workspace.set_migrate_options(options)
    let result = workspace.compile()
    if result.rc != 0: return tommy_fail(ctx, label ++ f" exited {result.rc}")
    0

fn tommy_reject_bad_output(ctx: &ActionCtx, generated: &str) -> i32:
    let fs = ctx.fs()
    var errors = 0
    var modules = 0
    for path in fs.list_files(generated):
        if not path.ends_with(".w"): continue
        modules = modules + 1
        let text = fs.read_text(path)
        if text.contains("@[c_export("):
            ctx.diagnostics().error("tommyds generated source contains a forbidden c_export attribute in " ++ path)
            errors = errors + 1
        if text.contains("// Bail:") or text.contains("[MIGRATOR_UNTRANSLATED]"):
            ctx.diagnostics().error("tommyds generated source contains untranslatable migrator output in " ++ path)
            errors = errors + 1
    // every engine module, defs.w and the check program
    let floor = tommy_modules().len() + 2
    if modules < floor:
        return tommy_fail(ctx, f"only {modules} generated .w files under " ++ generated ++ f"; expected at least {floor}")
    errors

// The .wo bundle root (docs/wo_bundles.md "Root"): one `use` per corpus
// module, bytewise by name; the harness is excluded.
pub fn tommy_bundle_root_text(module_paths: &Vec[str]) -> str:
    var names: Vec[str] = Vec.new()
    for path in module_paths:
        if not path.ends_with(".w"): continue
        let name = tommy_module_name(path)
        if name == "bundle" or tommy_is_harness(name): continue
        var placed = false
        var next: Vec[str] = Vec.new()
        for existing in names:
            if not placed and name < existing:
                next.push(name.clone())
                placed = true
            next.push(existing.clone())
        if not placed: next.push(name.clone())
        names = next
    var text = "// lib/std/tommyds/bundle.w — the TommyDS .wo bundle root (docs/wo_bundles.md).\n"
    text = text ++ "// Written by build/tommyds.w (tommyds-migrate) from the migrated module list:\n"
    text = text ++ "// one `use` per corpus module; check_ is the harness.\n"
    for name in names: text = text ++ "use " ++ TOMMY_PACKAGE ++ "." ++ name ++ "\n"
    text

pub fn run_tommy_migrate_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let reference = ctx.inputs()[0]
    let output = ctx.output()
    let source = tommy_scratch(ctx) ++ "/source"
    let generated = tommy_scratch(ctx) ++ "/generated"
    if tommy_reset(ctx, source) != 0 or tommy_reset(ctx, generated) != 0: return 1
    // Flat staging: the units and headers side by side, plus a tommyds/
    // header directory so check.c's `#include "tommyds/tommy.h"` resolves.
    if fs.mkdir_all(source ++ "/tommyds") != 0: return tommy_fail(ctx, "cannot create the header directory")
    for name in tommy_modules():
        for extension in [".c", ".h"]:
            if tommy_copy(ctx, reference ++ "/tommyds/" ++ name ++ extension, source ++ "/" ++ name ++ extension) != 0: return 1
        if tommy_copy(ctx, reference ++ "/tommyds/" ++ name ++ ".h", source ++ "/tommyds/" ++ name ++ ".h") != 0: return 1
    for name in tommy_headers():
        if tommy_copy(ctx, reference ++ "/tommyds/" ++ name ++ ".h", source ++ "/" ++ name ++ ".h") != 0: return 1
        if tommy_copy(ctx, reference ++ "/tommyds/" ++ name ++ ".h", source ++ "/tommyds/" ++ name ++ ".h") != 0: return 1
    if tommy_copy(ctx, reference ++ "/check.c", source ++ "/check.c") != 0: return 1
    if tommy_migrate(ctx, "tommyds-corpus", tommy_options(source, generated)) != 0: return 1
    if fs.write_text(generated ++ "/bundle.w", tommy_bundle_root_text(fs.list_files(generated))) != 0:
        return tommy_fail(ctx, "cannot write the bundle root")
    if tommy_copy(ctx, reference ++ "/LICENSE", generated ++ "/LICENSE") != 0: return 1
    if fs.write_text(generated ++ "/UPSTREAM", TOMMY_REVISION ++ "\nsha256=" ++ TOMMY_SHA256 ++ "\n") != 0: return 1
    if fs.exists(output) and fs.remove_tree(output) != 0: return tommy_fail(ctx, "cannot replace " ++ output)
    if fs.rename(generated, output) != 0: return tommy_fail(ctx, "cannot publish " ++ output)
    0

pub fn run_tommy_check_generated_action(ctx: ActionCtx) -> i32:
    if tommy_reject_bad_output(ctx, ctx.inputs()[0]) != 0: return 1
    if ctx.fs().write_text(ctx.output(), "ok\n") != 0: return tommy_fail(ctx, "cannot write " ++ ctx.output())
    0

// Promotion replaces every module under lib/std/tommyds with the migration's
// output: the checked-in corpus is generated, never hand-edited.
pub fn run_tommy_promote_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let generated = ctx.inputs()[0]
    let destination = ctx.output()
    if tommy_reject_bad_output(ctx, generated) != 0: return 1
    if fs.mkdir_all(destination) != 0: return tommy_fail(ctx, "cannot create " ++ destination)
    for path in fs.list_files(destination):
        if path.ends_with(".w") and fs.remove_file(path) != 0: return tommy_fail(ctx, "cannot remove " ++ path)
    var copied = 0
    for path in fs.list_files(generated):
        if not path.ends_with(".w"): continue
        if tommy_copy(ctx, path, destination ++ "/" ++ tommy_basename(path)) != 0: return 1
        copied = copied + 1
    print(f"promoted {copied} generated tommyds modules into " ++ tommy_abs(ctx, destination))
    0

pub fn run_tommy_bundle_root_check_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let root = ctx.inputs()[0]
    let corpus = ctx.args()[0]
    if fs.read_text(root) != tommy_bundle_root_text(fs.list_files(corpus)):
        return tommy_fail(ctx, root ++ " is not the bundle root the migrate action writes for " ++ corpus ++ " (one `use` per corpus module, sorted; check excluded)")
    if fs.write_text(ctx.output(), "ok\n") != 0: return tommy_fail(ctx, "cannot write " ++ ctx.output())
    0

// The corpora lane: upstream's check program, compiled from the checked-in
// corpus by the release binary against the embedded bundle, then run. It
// asserts internally and exits non-zero on any failure.
pub fn run_tommy_test_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let compiler = tommy_abs(ctx, ctx.inputs()[0])
    let output = ctx.output()
    if tommy_reset(ctx, output) != 0: return 1
    let binary = output ++ "/tommycheck"
    // Build-layer code runs on the seed: argv is pushed (#1122).
    var compile_args: Vec[str] = Vec.new()
    compile_args.push(compiler.clone())
    compile_args.push("build")
    compile_args.push("-O1")
    compile_args.push(TOMMY_CORPUS_DIR ++ "/check_.w")
    compile_args.push("-o")
    compile_args.push(tommy_abs(ctx, binary))
    let compiled = ctx.process_runner().run_capture(compile_args, tommy_abs(ctx, binary ++ ".compile.stdout"), tommy_abs(ctx, binary ++ ".compile.stderr"), 600000)
    if compiled.rc != 0: return tommy_fail(ctx, f"compile tommycheck exited {compiled.rc}\n" ++ fs.read_text(binary ++ ".compile.stderr"))
    var argv: Vec[str] = Vec.new()
    argv.push(tommy_abs(ctx, binary))
    let result = ctx.process_runner().run_capture(argv, tommy_abs(ctx, binary ++ ".stdout"), tommy_abs(ctx, binary ++ ".stderr"), 600000)
    if result.rc != 0: return tommy_fail(ctx, f"tommycheck exited {result.rc}\n" ++ result.stdout ++ result.stderr)
    if fs.write_text(output ++ "/report.txt", "upstream=" ++ TOMMY_REVISION ++ "\nPASS tommycheck\n") != 0: return 1
    print("upstream=" ++ TOMMY_REVISION ++ " tommycheck passed")
    0

pub fn tommy_pipeline(out: Build, release_compiler: &str) -> Build:
    let archive = "out/tommyds_reference/tommyds.tar.gz"
    let extracted = "out/tommyds_reference/extracted"
    let reference = extracted ++ "/tommyds-" ++ TOMMY_REVISION
    var graph = out.download("tommyds-download", Download {
        url: "https://codeload.github.com/amadvance/tommyds/tar.gz/" ++ TOMMY_REVISION,
        sha256: TOMMY_SHA256, output_path: archive.clone(),
    })
    graph = graph.extract_tar_gz("tommyds-reference", archive, extracted)
    var migrate = target_new(.Action, "tommyds-migrate", "").output("out/tommyds_migrated")
    migrate.action = run_tommy_migrate_action
    migrate = migrate.input(reference.clone()).dep("tommyds-reference")
    migrate = migrate.write_scope("out/tmp/action-scratch/tommyds-migrate")
    graph = graph.add_target(migrate)
    var check = target_new(.Action, "tommyds-check-generated", "").output("out/gen/.tommyds-check-generated-stamp")
    check.action = run_tommy_check_generated_action
    check = check.input("out/tommyds_migrated").dep("tommyds-migrate")
    graph = graph.add_target(check)
    var promote = target_new(.Action, "tommyds-promote", "").output(TOMMY_CORPUS_DIR)
    promote.action = run_tommy_promote_action
    promote = promote.write_scope("out/tmp/action-scratch/tommyds-promote")
    promote = promote.input("out/tommyds_migrated").dep("tommyds-check-generated")
    graph = graph.add_target(promote)
    var tests = target_new(.Action, "tommyds-test", "").output("out/corpus/tommyds-test")
    tests.action = run_tommy_test_action
    tests = tests.input(release_compiler.clone()).input(TOMMY_CORPUS_DIR ++ "/check_.w").dep("build")
    graph.add_target(tests)
