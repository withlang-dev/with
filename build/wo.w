module build.wo

// .wo bundles (docs/wo_bundles.md, decisions.md D38/D39): a migrated corpus
// compiles once into <name>.{o,manifest,wi} and is reused until the corpus,
// the target or an ABI-defining source changes.
//
//   key        = sha256(corpus_sha | target | abi_sha)
//   corpus_sha = sha256 of "<path>:<sha256(file)>\n" over every .w under
//                lib/<corpus>, bytewise by path
//   target     = the platform the object is compiled for, in the compiler's
//                spelling (src/TargetSpec.w target_spec_resolved_name)
//   abi_sha    = sha256(docs/with-abi.sha256), the identity every compiler
//                binary carries (`with version --abi-sha`)
//
// The store ($WITH_WO_DIR, else ~/.local/with-wo) holds one slot per
// bundle, target and ABI: <store>/<name>/<target>-<abi_sha>/<name>.{o,wi,
// manifest}; the manifest records the key and the corpus hash, so a corpus
// change rebuilds the slot. (Only the corpus hash needs text hashing, and
// only the action — native code — can hash text: the graph plan runs under
// the comptime evaluator, which serves ToolFs.sha256_file natively and
// nothing else, so the slot path uses just that and the plan never hashes.)
//
// Per bundle and target: `<name>-wo-build` writes out/wo/<name>.{o,wi,
// manifest} — copied from the slot when it holds this corpus (nothing
// compiles), else compiled by the stage whose ABI stamp equals abi_sha
// (stage1 for the tree's ABI) and proven by the second fingerprint pass on
// the emitted .wi; `<name>-wo-install-{o,wi,manifest}` publish out/wo/ into
// the slot (the .Install kind: temp sibling + rename; the manifest last, so
// a torn slot never reads as present); `<name>-wo` groups them. Consumers
// (the embedded blobs, a stage link's --link-bundle out/wo/<name>) read
// out/wo/. A cross target's bundle (#946) is the same plan with a triple:
// the release compiler compiles it with --target=<triple> — the object, the
// interface, the manifest and BOTH fingerprint passes under that target —
// its targets are `<name>-wo-<os>-<arch>…`, its tree copy is
// out/wo/<target>/<name>.*, and the cross compiler for that target embeds it.
//
// A test points WITH_WO_DIR at a scratch directory; the real store is never
// written by one.

use std.build
use std.process
use std.sysinfo
use build.compiler
fn wo_owned_text(s: &str): s ++ ""

pub type WoBundle {
    name: str,
    // `--bundle-corpus` spelling: the corpus under the embedded std tree
    corpus_rel: str,
    // the tree directory the corpus_sha hashes
    corpus_dir: str,
    root: str,
    target: str,
    // `--target=<triple>` for a cross bundle; "" compiles for the host
    triple: str,
    abi_sha: str,
    // the tree copy every consumer reads: out/wo for the host bundle,
    // out/wo/<target> for a cross one, so the two never collide
    tree_dir: str,
    // <store>/<name>/<target>-<abi_sha>, as the action reads it
    slot: str,
    // the same slot as the .Install kind spells a destination: `$HOME/…`
    // for a store under the home directory, project-relative otherwise
    install_slot: str,
}

fn wo_fail(ctx: &ActionCtx, message: &str) -> i32:
    ctx.diagnostics().error(ctx.target_name() ++ ": " ++ message)
    1

fn wo_abs(root: &str, path: &str) -> str:
    if path.len() > 0 and path.byte_at(0) == '/':
        return wo_owned_text(path)
    root ++ "/" ++ path

fn wo_arg_value(args: &Vec[str], prefix: &str) -> str:
    for i in 0..args.len() as i32:
        let arg = args[i]
        if arg.starts_with(prefix):
            return wo_owned_text(arg.slice(prefix.len(), arg.len()))
    ""

// sha256 of an in-memory string. The build action runs under the comptime
// evaluator (the seed drives `with build` without the native action runner),
// which serves ToolFs.sha256_file but not the raw-pointer `sha256_hash_str`
// (`&raw mut`, NK_UNARY kind 26 — the evaluator does not model raw pointers
// into a mutable stack buffer). So stage the bytes into the action's own
// project-relative scratch dir and hash the file: byte-identical to hashing
// the string directly, and legal under comptime. A store slot can live
// outside the project root, so its callers host_read_text the file and hand
// the bytes here rather than sha256_file the out-of-root path.
fn wo_sha256_text(fs: &ToolFs, text: &str) -> str:
    let scratch = fs.scratch_dir()
    let _m = fs.mkdir_all(scratch)
    let staged = scratch ++ "/wo-sha256.in"
    let _w = fs.write_text(staged, text)
    fs.sha256_file(staged)

fn wo_dirname(path: &str) -> str:
    var last: i64 = -1
    for i in 0..path.len():
        if path.byte_at(i) == '/':
            last = i
    if last < 0:
        return "."
    wo_owned_text(path.slice(0, last))

fn wo_first_line(text: &str) -> str:
    var end: i64 = 0
    while end < text.len() and text.byte_at(end) != '\n' and text.byte_at(end) != '\r':
        end = end + 1
    wo_owned_text(text.slice(0, end))

// The value of a manifest's `<key> <value>` line ("" if absent).
pub fn wo_manifest_field(manifest: &str, key: &str) -> str:
    let want = key ++ " "
    var start: i64 = 0
    while start < manifest.len():
        var end = start
        while end < manifest.len() and manifest.byte_at(end) != '\n':
            end = end + 1
        let line = manifest.slice(start, end)
        if line.starts_with(want):
            let rest = line.slice(want.len(), line.len())
            var sp: i64 = 0
            while sp < rest.len() and rest.byte_at(sp) != ' ':
                sp = sp + 1
            return wo_owned_text(rest.slice(0, sp))
        start = end + 1
    ""

// The store directory: $WITH_WO_DIR, else ~/.local/with-wo. Both are
// graph inputs (env_input), so a change re-plans.
pub fn wo_store_dir(ctx: &BuildCtx) -> str:
    let explicit = ctx.env_input("WITH_WO_DIR")
    if explicit.len() > 0:
        return explicit
    ctx.env_input("HOME") ++ "/.local/with-wo"

// The store as an .Install destination: the kind writes outside the project
// only under `$HOME/`, so a store beneath the home directory is spelled
// that way; WITH_WO_DIR is otherwise project-relative (a test's scratch
// store under out/).
fn wo_store_install_dir(ctx: &BuildCtx) -> str:
    let store = wo_store_dir(ctx)
    let home = ctx.env_input("HOME")
    if home.len() > 0 and store.starts_with(home ++ "/"):
        return "$HOME/" ++ store.slice(home.len() + 1, store.len())
    store

// The host platform in the compiler's spelling (src/TargetSpec.w
// target_spec_resolved_name). The build action checks the manifest's
// `target` line against it, so this table and the compiler's cannot drift
// unnoticed.
pub fn wo_host_target() -> str:
    let host_os = os()
    let host_arch = arch()
    let arch_name = if comp_arch_is_aarch64(host_arch): "aarch64" else: wo_owned_text(host_arch)
    if host_os == "Macos":
        return "darwin_" ++ arch_name
    if host_os == "Linux":
        return "linux_" ++ arch_name
    if host_os == "Windows":
        return "windows_" ++ arch_name
    ""

fn wo_w_files(fs: &ToolFs, dir: &str) -> Vec[str]:
    let listing = fs.list_files(dir)
    let out: Vec[str] = Vec.new()
    for i in 0..listing.len() as i32:
        let path = listing[i]
        if path.ends_with(".w"):
            out.push(wo_owned_text(path))
    comp_sort_strings(move out)

// sha256 over "<path>:<sha256(file)>\n" for every .w file under dir, bytewise
// by path (the build cache's build_cache_hash_directory_w_files shape).
fn wo_corpus_sha(fs: &ToolFs, dir: &str) -> str:
    let files = wo_w_files(fs, dir)
    var combined = ""
    for i in 0..files.len() as i32:
        let path = files[i]
        combined = combined ++ path ++ ":" ++ fs.sha256_file(path) ++ "\n"
    wo_sha256_text(fs, combined)

// The bundle's plan for the host: everything the graph needs to name its
// targets and paths, none of it hashed text.
pub fn wo_bundle_plan(ctx: &BuildCtx, name: &str, corpus_rel: &str, root: &str) -> WoBundle:
    wo_bundle_plan_for_target(ctx, name, corpus_rel, root, wo_host_target(), "")

// The plan for one target: `target_name` in the compiler's spelling (the
// slot's key and the manifest's `target` line, which the build action
// checks), `triple` the `--target` the release compiler takes to compile
// for it — "" is the host plan.
pub fn wo_bundle_plan_for_target(ctx: &BuildCtx, name: &str, corpus_rel: &str, root: &str, target_name: &str, triple: &str) -> WoBundle:
    let abi_sha = ctx.fs().sha256_file("docs/with-abi.sha256")
    let slot_rel = "/" ++ name ++ "/" ++ target_name ++ "-" ++ abi_sha
    WoBundle {
        name: wo_owned_text(name),
        corpus_rel: wo_owned_text(corpus_rel),
        corpus_dir: "lib/" ++ corpus_rel,
        root: wo_owned_text(root),
        target: wo_owned_text(target_name),
        triple: wo_owned_text(triple),
        abi_sha,
        tree_dir: if triple.len() > 0: "out/wo/" ++ target_name else: "out/wo",
        slot: wo_store_dir(ctx) ++ slot_rel,
        install_slot: wo_store_install_dir(ctx) ++ slot_rel,
    }

// out/wo/<name> (out/wo/<target>/<name> for a cross bundle): the tree's copy
// every consumer reads.
pub fn wo_prefix(plan: &WoBundle) -> str:
    plan.tree_dir ++ "/" ++ plan.name

// <store>/<name>/<target>-<abi_sha>/<name>: the published copy.
pub fn wo_store_prefix(plan: &WoBundle) -> str:
    plan.slot ++ "/" ++ plan.name

// The stem of the bundle's target names: `<name>-wo` for the host,
// `<name>-wo-<os>-<arch>` for a cross target (build.w spells platforms
// `linux-x86_64` in target names and `linux_x86_64` in paths).
fn wo_target_stem(plan: &WoBundle) -> str:
    if plan.triple.len() == 0:
        return plan.name ++ "-wo"
    plan.name ++ "-wo-" ++ wo_target_label(plan.target)

// "linux_x86_64" -> "linux-x86_64"
fn wo_target_label(target: &str) -> str:
    for i in 0..target.len():
        if target.byte_at(i) == '_':
            return target.slice(0, i) ++ "-" ++ target.slice(i + 1, target.len())
    wo_owned_text(target)

pub fn wo_build_target_name(plan: &WoBundle) -> str:
    wo_target_stem(plan) ++ "-build"

pub fn wo_group_target_name(plan: &WoBundle) -> str:
    wo_target_stem(plan)

// Registers `<name>-wo-build`, the three installs and the `<name>-wo` group
// (with the target label for a cross plan). `compiler` builds the bundle
// when the slot lacks this corpus: the stage whose ABI stamp is abi_sha
// (compiler_dep produces it) — the release compiler for a cross target.
pub fn wo_bundle_targets(out: Build, ctx: &BuildCtx, plan: &WoBundle, compiler: &str, compiler_dep: &str) -> Build:
    var graph = out
    let fs_prefix = wo_prefix(plan)
    let store_prefix = plan.install_slot ++ "/" ++ plan.name
    let build_name = wo_build_target_name(plan)
    var build_target = target_new(.Action, wo_owned_text(build_name), "").output(fs_prefix ++ ".manifest")
    build_target.action = run_wo_bundle_build_action
    build_target = build_target.extra_output(fs_prefix ++ ".o")
    build_target = build_target.extra_output(fs_prefix ++ ".wi")
    build_target = build_target.compiler(compiler)
    build_target = build_target.arg("name=" ++ plan.name)
    build_target = build_target.arg("corpus=" ++ plan.corpus_rel)
    build_target = build_target.arg("corpus-dir=" ++ plan.corpus_dir)
    build_target = build_target.arg("root=" ++ plan.root)
    build_target = build_target.arg("target=" ++ plan.target)
    build_target = build_target.arg("triple=" ++ plan.triple)
    build_target = build_target.arg("abi-sha=" ++ plan.abi_sha)
    build_target = build_target.arg("slot=" ++ plan.slot)
    build_target = build_target.arg("prefix=" ++ fs_prefix)
    build_target = build_target.input(wo_owned_text(compiler))
    build_target = build_target.input("docs/with-abi.sha256")
    build_target = target_with_wo_corpus_inputs(move build_target, ctx, plan)
    build_target = build_target.write_scope(wo_owned_text(plan.tree_dir))
    build_target = build_target.write_scope("out/command/" ++ build_name)
    build_target = build_target.timeout(900000)
    build_target = build_target.dep(wo_owned_text(compiler_dep))
    graph = graph.add_target(build_target)

    // Published in this order so the manifest — the record the presence
    // check trusts — lands after the files it describes.
    let exts: Vec[str] = Vec.new()
    exts.push("o")
    exts.push("wi")
    exts.push("manifest")
    var previous = wo_owned_text(build_name)
    var group = target_new(.Group, wo_group_target_name(plan), "")
    for ei in 0..exts.len() as i32:
        let ext = exts[ei]
        let install_name = wo_target_stem(plan) ++ "-install-" ++ ext
        var install = target_new(.Install, wo_owned_text(install_name), fs_prefix ++ "." ++ ext).output(store_prefix ++ "." ++ ext)
        install = install.input(fs_prefix ++ "." ++ ext)
        install = install.arg("0644")
        install = install.dep(wo_owned_text(previous))
        graph = graph.add_target(install)
        group = group.dep(wo_owned_text(install_name))
        previous = install_name
    graph.add_target(group)

// Every .w file of the corpus as inputs: a corpus edit re-runs the target.
pub fn target_with_wo_corpus_inputs(target: Target, ctx: &BuildCtx, plan: &WoBundle) -> Target:
    var out = target
    let corpus_files = wo_w_files(ctx.fs(), plan.corpus_dir)
    for fi in 0..corpus_files.len() as i32:
        out = out.input(wo_owned_text(corpus_files[fi]))
    out

// The wo-drift lane (docs/wo_bundles.md "Lanes"): `<name>-wo-drift`
// rebuilds the bundle to a scratch object with the release compiler. The
// interface, the fingerprint and the manifest's ABI and target must be
// identical — a difference there is declaration drift the ABI hash did not
// catch, a hard error. The object bytes are compared too: identical proves
// the bundle deterministic across compiler generations; different means
// codegen changed since the stored object was built (D38 keeps it: a .wo
// is rebuilt only when its corpus or the ABI changes, never because the
// compiler did), so the corpus's harness (`harness`, e.g. pcre2test.w, its
// `use std.<corpus>.*` resolving to the interface) runs against BOTH
// objects — the stored one through the embedded bundle, the fresh one
// through --link-bundle — with `harness-arg` for a smoke check, and both
// must pass. The upstream suite runs against the stored one in
// `<name>-wo-test`.
pub fn wo_drift_target_name(plan: &WoBundle) -> str:
    wo_target_stem(plan) ++ "-drift"

pub fn wo_drift_dir(plan: &WoBundle) -> str:
    "out/wo-drift/" ++ plan.name

pub fn wo_drift_harness_bin(plan: &WoBundle, harness: &str) -> str:
    wo_drift_dir(plan) ++ "/" ++ wo_basename_no_ext(harness)

fn wo_basename_no_ext(path: &str) -> str:
    var start: i64 = 0
    for i in 0..path.len():
        if path.byte_at(i) == '/':
            start = i + 1
    var end = path.len()
    for j in start..path.len():
        if path.byte_at(j) == '.':
            end = j
    wo_owned_text(path.slice(start, end))

pub fn wo_drift_target(ctx: &BuildCtx, plan: &WoBundle, compiler: &str, compiler_dep: &str, harness: &str, harness_arg: &str) -> Target:
    let name = wo_drift_target_name(plan)
    let dir = wo_drift_dir(plan)
    var target = target_new(.Action, wo_owned_text(name), "").output(dir ++ "/stamp")
    target.action = run_wo_drift_action
    target = target.extra_output(wo_drift_harness_bin(plan, harness))
    target = target.compiler(compiler)
    target = target.arg("name=" ++ plan.name)
    target = target.arg("corpus=" ++ plan.corpus_rel)
    target = target.arg("root=" ++ plan.root)
    target = target.arg("harness=" ++ harness)
    target = target.arg("harness-arg=" ++ harness_arg)
    target = target.arg("dir=" ++ dir)
    target = target.input(wo_owned_text(compiler))
    target = target.input(wo_owned_text(harness))
    let kinds: Vec[str] = Vec.new()
    kinds.push("o")
    kinds.push("wi")
    kinds.push("manifest")
    for ki in 0..kinds.len() as i32:
        target = target.input(wo_prefix(plan) ++ "." ++ kinds[ki])
    target = target_with_wo_corpus_inputs(move target, ctx, plan)
    target = target.write_scope(wo_owned_text(dir))
    target = target.write_scope("out/command/" ++ name)
    target = target.timeout(900000)
    target = target.dep(wo_owned_text(compiler_dep))
    target = target.dep(wo_group_target_name(plan))
    target

pub fn run_wo_drift_action(ctx: ActionCtx) -> i32:
    let args = ctx.args()
    let name = wo_arg_value(args, "name=")
    let corpus = wo_arg_value(args, "corpus=")
    let root_path = wo_arg_value(args, "root=")
    let harness = wo_arg_value(args, "harness=")
    let harness_arg = wo_arg_value(args, "harness-arg=")
    let dir = wo_arg_value(args, "dir=")
    let compiler = wo_arg_value(args, "compiler=")
    if name.len() == 0 or corpus.len() == 0 or root_path.len() == 0 or harness.len() == 0 or dir.len() == 0 or compiler.len() == 0:
        return wo_fail(ctx, "requires name=, corpus=, root=, harness=, harness-arg=, dir= and compiler= arguments")
    let fs = ctx.fs()
    let root = ctx.project_info().project_root()
    let capture_dir = "out/command/" ++ ctx.target_name()
    if fs.exists(dir) and fs.remove_tree(dir) != 0:
        return wo_fail(ctx, "could not clear " ++ dir)
    if fs.mkdir_all(dir) != 0 or fs.mkdir_all(capture_dir) != 0:
        return wo_fail(ctx, "could not create " ++ dir)
    let stored = "out/wo/" ++ name
    let scratch = dir ++ "/" ++ name

    // The rebuild: same corpus, same ABI, this compiler generation.
    var build_args: Vec[str] = Vec.new()
    build_args.push(wo_abs(root, compiler))
    build_args.push("build")
    build_args.push(wo_abs(root, root_path))
    build_args.push("--emit-obj")
    build_args.push("--bundle-corpus")
    build_args.push(wo_owned_text(corpus))
    build_args.push("--emit-bundle-interface")
    build_args.push(wo_abs(root, scratch ++ ".wi"))
    build_args.push("--emit-bundle-manifest")
    build_args.push(wo_abs(root, scratch ++ ".manifest"))
    build_args.push("--bundle-fingerprint")
    build_args.push(wo_abs(root, scratch ++ ".fp"))
    build_args.push("-O1")
    build_args.push("-o")
    build_args.push(wo_abs(root, scratch ++ ".o"))
    let built = wo_run(ctx, "rebuild", &build_args, ctx.timeout())
    if built.rc != 0:
        return wo_fail(ctx, f"scratch rebuild of the bundle failed with exit code {built.rc}; stderr: " ++ capture_dir ++ "/rebuild.stderr")
    if fs.read_text(stored ++ ".wi") != fs.read_text(scratch ++ ".wi"):
        return wo_fail(ctx, "declaration drift: " ++ scratch ++ ".wi rebuilt by " ++ compiler ++ " differs from " ++ stored ++ ".wi (corpus and ABI unchanged); diff them before anything else")
    let stored_manifest = fs.read_text(stored ++ ".manifest")
    let scratch_manifest = fs.read_text(scratch ++ ".manifest")
    let fields: Vec[str] = Vec.new()
    fields.push("abi-sha")
    fields.push("target")
    fields.push("fingerprint")
    fields.push("interface-sha")
    for fi in 0..fields.len() as i32:
        let field = fields[fi]
        if wo_manifest_field(stored_manifest, field) != wo_manifest_field(scratch_manifest, field):
            return wo_fail(ctx, "declaration drift: manifest `" ++ field ++ "` differs between " ++ stored ++ " and " ++ scratch)
    let stored_o = if fs.exists(stored ++ ".o"): fs.read_text(stored ++ ".o") else: ""
    let scratch_o = if fs.exists(scratch ++ ".o"): fs.read_text(scratch ++ ".o") else: ""
    if stored_o.len() == 0 or scratch_o.len() == 0:
        return wo_fail(ctx, "no object to compare (" ++ stored ++ ".o, " ++ scratch ++ ".o)")
    let identical = stored_o == scratch_o

    // The harness against the stored bundle (embedded; the link selects it
    // on demand) and, when the bytes moved, against the fresh one too.
    let harness_bin = dir ++ "/" ++ wo_basename_no_ext(harness)
    let rc_stored = wo_drift_run_harness(ctx, compiler, harness, harness_arg, harness_bin, "", "stored")
    if rc_stored != 0: return rc_stored
    if not identical:
        let rc_fresh = wo_drift_run_harness(ctx, compiler, harness, harness_arg, harness_bin ++ "-fresh", scratch, "fresh")
        if rc_fresh != 0: return rc_fresh
    if fs.write_text(dir ++ "/stamp", "ok\n") != 0:
        return wo_fail(ctx, "could not write " ++ dir ++ "/stamp")
    if identical:
        print("[" ++ ctx.target_name() ++ "] " ++ scratch ++ ".o is byte-identical to " ++ stored ++ ".o; " ++ harness_bin ++ " links the bundle and runs")
    else:
        print("[" ++ ctx.target_name() ++ "] " ++ stored ++ ".o was built by an earlier compiler generation: " ++ scratch ++ ".o differs (same interface, fingerprint, ABI and target) and both pass the harness; remove the store slot to converge on the current bytes")
    0

// Builds `harness` against the bundle — the embedded one, or `<bundle>` via
// --link-bundle — and runs it with `harness_arg`.
fn wo_drift_run_harness(ctx: &ActionCtx, compiler: &str, harness: &str, harness_arg: &str, harness_bin: &str, bundle: &str, label: &str) -> i32:
    let root = ctx.project_info().project_root()
    let capture_dir = "out/command/" ++ ctx.target_name()
    var harness_args: Vec[str] = Vec.new()
    harness_args.push(wo_abs(root, compiler))
    harness_args.push("build")
    harness_args.push(wo_abs(root, harness))
    if bundle.len() > 0:
        harness_args.push("--link-bundle")
        harness_args.push(wo_abs(root, bundle))
    harness_args.push("-O1")
    harness_args.push("-o")
    harness_args.push(wo_abs(root, harness_bin))
    let built = wo_run(ctx, "harness-build-" ++ label, &harness_args, ctx.timeout())
    if built.rc != 0:
        return wo_fail(ctx, f"harness build against the {label} bundle failed with exit code {built.rc}; stderr: " ++ capture_dir ++ "/harness-build-" ++ label ++ ".stderr")
    var run_args: Vec[str] = Vec.new()
    run_args.push(wo_abs(root, harness_bin))
    if harness_arg.len() > 0:
        run_args.push(wo_owned_text(harness_arg))
    let ran = wo_run(ctx, "harness-run-" ++ label, &run_args, 120000)
    if ran.rc != 0:
        return wo_fail(ctx, f"harness linked against the {label} bundle failed with exit code {ran.rc}; stderr: " ++ capture_dir ++ "/harness-run-" ++ label ++ ".stderr")
    0

// "" when the slot holds a coherent bundle of this corpus, else why not.
fn wo_slot_status(fs: &ToolFs, store_prefix: &str, corpus_sha: &str, target: &str, abi_sha: &str) -> str:
    let exts: Vec[str] = Vec.new()
    exts.push("o")
    exts.push("wi")
    exts.push("manifest")
    for ei in 0..exts.len() as i32:
        let path = store_prefix ++ "." ++ exts[ei]
        if not fs.host_exists(path):
            return "store lacks " ++ path
    let manifest = fs.host_read_text(store_prefix ++ ".manifest")
    if wo_manifest_field(manifest, "corpus-sha") != corpus_sha:
        return store_prefix ++ ".manifest was built from corpus " ++ wo_manifest_field(manifest, "corpus-sha") ++ ", the tree's is " ++ corpus_sha
    if wo_manifest_field(manifest, "target") != target or wo_manifest_field(manifest, "abi-sha") != abi_sha:
        return store_prefix ++ ".manifest names target " ++ wo_manifest_field(manifest, "target") ++ " and ABI " ++ wo_manifest_field(manifest, "abi-sha") ++ ", not this slot's"
    let wi_sha = wo_sha256_text(fs, fs.host_read_text(store_prefix ++ ".wi"))
    if wo_manifest_field(manifest, "interface-sha") != wi_sha:
        return store_prefix ++ ".wi (sha256 " ++ wi_sha ++ ") is not the interface the stored manifest was built with"
    let object_sha = wo_sha256_text(fs, fs.host_read_text(store_prefix ++ ".o"))
    if wo_manifest_field(manifest, "object-sha") != object_sha:
        return store_prefix ++ ".o (sha256 " ++ object_sha ++ ") is not the object the stored manifest was built with"
    ""

fn wo_run(ctx: &ActionCtx, label: &str, argv: &Vec[str], timeout_ms: i32) -> ToolProcessResult:
    let root = ctx.project_info().project_root()
    let capture_dir = "out/command/" ++ ctx.target_name()
    var process_env = process_env()
    process_env = process_env.set("WITH_OUT_DIR", wo_abs(root, "out"))
    ctx.process_runner().run_capture_with_env(argv, wo_abs(root, capture_dir ++ "/" ++ label ++ ".stdout"), wo_abs(root, capture_dir ++ "/" ++ label ++ ".stderr"), timeout_ms, process_env)

pub fn run_wo_bundle_build_action(ctx: ActionCtx) -> i32:
    let args = ctx.args()
    let name = wo_arg_value(args, "name=")
    let corpus = wo_arg_value(args, "corpus=")
    let corpus_dir = wo_arg_value(args, "corpus-dir=")
    let root_path = wo_arg_value(args, "root=")
    let target = wo_arg_value(args, "target=")
    let triple = wo_arg_value(args, "triple=")
    let abi_sha = wo_arg_value(args, "abi-sha=")
    let slot = wo_arg_value(args, "slot=")
    let prefix = wo_arg_value(args, "prefix=")
    let compiler = wo_arg_value(args, "compiler=")
    if name.len() == 0 or corpus.len() == 0 or corpus_dir.len() == 0 or root_path.len() == 0 or target.len() == 0 or abi_sha.len() != 64 or slot.len() == 0 or prefix.len() == 0 or compiler.len() == 0:
        return wo_fail(ctx, "requires name=, corpus=, corpus-dir=, root=, target=, triple=, abi-sha=, slot=, prefix= and compiler= arguments")
    let fs = ctx.fs()
    let root = ctx.project_info().project_root()
    let tree_dir = wo_dirname(prefix)
    let store_prefix = slot ++ "/" ++ name
    let capture_dir = "out/command/" ++ ctx.target_name()
    if fs.mkdir_all(tree_dir) != 0 or fs.mkdir_all(capture_dir) != 0:
        return wo_fail(ctx, "could not create " ++ tree_dir)
    let corpus_sha = wo_corpus_sha(fs, corpus_dir)
    let key = wo_sha256_text(fs, corpus_sha ++ "|" ++ target ++ "|" ++ abi_sha)

    // Present: the slot holds this corpus, coherently — copy it in.
    let missing = wo_slot_status(fs, store_prefix, corpus_sha, target, abi_sha)
    if missing.len() == 0:
        let exts: Vec[str] = Vec.new()
        exts.push("o")
        exts.push("wi")
        exts.push("manifest")
        for ei in 0..exts.len() as i32:
            let ext = exts[ei]
            if fs.write_text(prefix ++ "." ++ ext, fs.host_read_text(store_prefix ++ "." ++ ext)) != 0:
                return wo_fail(ctx, "could not copy " ++ store_prefix ++ "." ++ ext ++ " into " ++ tree_dir)
        print("[" ++ ctx.target_name() ++ "] " ++ store_prefix ++ ".{o,wi,manifest} holds key " ++ key ++ " (corpus, target and ABI unchanged): compiled nothing")
        return 0
    print("[" ++ ctx.target_name() ++ "] " ++ missing ++ "; building " ++ name ++ " for " ++ target ++ " key " ++ key ++ " with " ++ compiler)

    // Only the compiler carrying the slot's ABI identity builds a bundle; an
    // unstamped binary carries the sentinel and never matches.
    var abi_args: Vec[str] = Vec.new()
    abi_args.push(wo_abs(root, compiler))
    abi_args.push("version")
    abi_args.push("--abi-sha")
    let abi = wo_run(ctx, "abi-sha", &abi_args, 120000)
    let stamp = wo_first_line(abi.stdout)
    if abi.rc != 0 or stamp != abi_sha:
        return wo_fail(ctx, "refusing to build bundle " ++ name ++ ": " ++ compiler ++ " carries ABI '" ++ stamp ++ "' (an unstamped compiler carries the sentinel) and the slot needs " ++ abi_sha)

    let tmp = tree_dir ++ "/tmp/" ++ name
    if fs.exists(tmp) and fs.remove_tree(tmp) != 0:
        return wo_fail(ctx, "could not clear " ++ tmp)
    if fs.mkdir_all(tmp) != 0:
        return wo_fail(ctx, "could not create " ++ tmp)
    let tmp_o = tmp ++ "/bundle.o"
    let tmp_wi = tmp ++ "/bundle.wi"
    let tmp_manifest = tmp ++ "/bundle.manifest"
    let fp_source = tmp ++ "/fingerprint.source"
    let fp_wi = tmp ++ "/fingerprint.wi"
    var build_args: Vec[str] = Vec.new()
    build_args.push(wo_abs(root, compiler))
    build_args.push("build")
    build_args.push(wo_abs(root, root_path))
    build_args.push("--emit-obj")
    if triple.len() > 0:
        build_args.push("--target=" ++ triple)
    build_args.push("--bundle-corpus")
    build_args.push(wo_owned_text(corpus))
    build_args.push("--emit-bundle-interface")
    build_args.push(wo_abs(root, tmp_wi))
    build_args.push("--emit-bundle-manifest")
    build_args.push(wo_abs(root, tmp_manifest))
    build_args.push("--bundle-fingerprint")
    build_args.push(wo_abs(root, fp_source))
    build_args.push("-O1")
    build_args.push("-o")
    build_args.push(wo_abs(root, tmp_o))
    let built = wo_run(ctx, "build", &build_args, ctx.timeout())
    if built.rc != 0:
        return wo_fail(ctx, f"bundle build failed with exit code {built.rc}; stderr: " ++ capture_dir ++ "/build.stderr")
    if not fs.exists(tmp_o) or not fs.exists(tmp_wi) or not fs.exists(tmp_manifest) or not fs.exists(fp_source):
        return wo_fail(ctx, "bundle build wrote no object, interface, manifest or fingerprint under " ++ tmp)

    // D39: the interface must reproduce the source's exported-declaration
    // graph exactly — the second fingerprint pass, out of process, under the
    // same target (layouts are the target's).
    var check_args: Vec[str] = Vec.new()
    check_args.push(wo_abs(root, compiler))
    check_args.push("check")
    check_args.push(wo_abs(root, tmp_wi))
    if triple.len() > 0:
        check_args.push("--target=" ++ triple)
    check_args.push("--bundle-corpus")
    check_args.push(wo_owned_text(corpus))
    check_args.push("--bundle-fingerprint")
    check_args.push(wo_abs(root, fp_wi))
    let checked = wo_run(ctx, "check-wi", &check_args, ctx.timeout())
    if checked.rc != 0:
        return wo_fail(ctx, f"check of the emitted interface failed with exit code {checked.rc}; stderr: " ++ capture_dir ++ "/check-wi.stderr")
    let source_fp = wo_first_line(fs.read_text(fp_source))
    let wi_fp = wo_first_line(fs.read_text(fp_wi))
    if source_fp.len() != 64 or source_fp != wi_fp:
        return wo_fail(ctx, "fingerprint of the emitted interface (" ++ wi_fp ++ ") differs from the source fingerprint (" ++ source_fp ++ "); diff " ++ fp_source ++ ".tsv against " ++ fp_wi ++ ".tsv")

    // The compiler's manifest names the ABI and target it compiled for; the
    // slot must be theirs. build.w adds the bundle name, the key, the corpus
    // hash and the object hash.
    var manifest = fs.read_text(tmp_manifest)
    if wo_manifest_field(manifest, "abi-sha") != abi_sha:
        return wo_fail(ctx, "the manifest records abi-sha '" ++ wo_manifest_field(manifest, "abi-sha") ++ "', the slot needs " ++ abi_sha)
    if wo_manifest_field(manifest, "target") != target:
        return wo_fail(ctx, "the compiler names its target '" ++ wo_manifest_field(manifest, "target") ++ "' but build/wo.w planned '" ++ target ++ "' (the plan's target spelling and src/TargetSpec.w target_spec_resolved_name disagree)")
    if wo_manifest_field(manifest, "interface-sha") != wo_sha256_text(fs, fs.read_text(tmp_wi)):
        return wo_fail(ctx, "the manifest's interface-sha is not the sha256 of " ++ tmp_wi)
    if wo_manifest_field(manifest, "fingerprint") != source_fp:
        return wo_fail(ctx, "the manifest's fingerprint is not the source fingerprint")
    manifest = manifest ++ "name " ++ name ++ "\n"
    manifest = manifest ++ "key " ++ key ++ "\n"
    manifest = manifest ++ "corpus-sha " ++ corpus_sha ++ "\n"
    manifest = manifest ++ "object-sha " ++ wo_sha256_text(fs, fs.read_text(tmp_o)) ++ "\n"

    // Into the tree copy: object, interface, then the manifest.
    if fs.rename(tmp_o, prefix ++ ".o") != 0:
        return wo_fail(ctx, "could not move " ++ tmp_o ++ " to " ++ prefix ++ ".o")
    if fs.rename(tmp_wi, prefix ++ ".wi") != 0:
        return wo_fail(ctx, "could not move " ++ tmp_wi ++ " to " ++ prefix ++ ".wi")
    if fs.write_text(prefix ++ ".manifest", manifest) != 0:
        return wo_fail(ctx, "could not write " ++ prefix ++ ".manifest")
    print("[" ++ ctx.target_name() ++ "] built " ++ prefix ++ ".{o,wi,manifest} key " ++ key)
    0
