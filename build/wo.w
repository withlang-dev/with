module build.wo

// .wo bundles (docs/wo_bundles.md, decisions.md D38/D39): a migrated corpus
// compiles once into <name>.{o,manifest,wi} and is reused until the corpus,
// the target or an ABI-defining source changes.
//
//   key        = sha256(corpus_sha | target | abi_sha)
//   corpus_sha = sha256 of "<path>:<sha256(file)>\n" over every .w under
//                lib/<corpus>, bytewise by path
//   target     = the host platform in the compiler's spelling
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
// Per bundle: `<name>-wo-build` writes out/wo/<name>.{o,wi,manifest} —
// copied from the slot when it holds this corpus (nothing compiles), else
// compiled by the stage whose ABI stamp equals abi_sha (stage1 for the
// tree's ABI) and proven by the second fingerprint pass on the emitted .wi;
// `<name>-wo-install-{o,wi,manifest}` publish out/wo/ into the slot (the
// .Install kind: temp sibling + rename; the manifest last, so a torn slot
// never reads as present); `<name>-wo` groups them. Consumers (the embedded
// blobs, a stage link's --link-bundle out/wo/<name>) read out/wo/.
//
// A test points WITH_WO_DIR at a scratch directory; the real store is never
// written by one.

use std.build
use std.process
use std.sysinfo
use std.crypto.sha256
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
    abi_sha: str,
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
        let arg = args.get(i as i64)
        if arg.starts_with(prefix):
            return wo_owned_text(arg.slice(prefix.len(), arg.len()))
    ""

fn wo_sha256_text(text: &str) -> str:
    var digest: [32]u8 = [0 as u8; 32]
    sha256_hash_str(text, &raw mut digest[0] as *mut u8)
    sha256_hex(&digest[0] as *const u8)

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
        let path = listing.get(i as i64)
        if path.ends_with(".w"):
            out.push(wo_owned_text(path))
    comp_sort_strings(move out)

// sha256 over "<path>:<sha256(file)>\n" for every .w file under dir, bytewise
// by path (the build cache's build_cache_hash_directory_w_files shape).
fn wo_corpus_sha(fs: &ToolFs, dir: &str) -> str:
    let files = wo_w_files(fs, dir)
    var combined = ""
    for i in 0..files.len() as i32:
        let path = files.get(i as i64)
        combined = combined ++ path ++ ":" ++ fs.sha256_file(path) ++ "\n"
    wo_sha256_text(combined)

// The bundle's plan: everything the graph needs to name its targets and
// paths, none of it hashed text.
pub fn wo_bundle_plan(ctx: &BuildCtx, name: &str, corpus_rel: &str, root: &str) -> WoBundle:
    let target = wo_host_target()
    let abi_sha = ctx.fs().sha256_file("docs/with-abi.sha256")
    let slot_rel = "/" ++ name ++ "/" ++ target ++ "-" ++ abi_sha
    WoBundle {
        name: wo_owned_text(name),
        corpus_rel: wo_owned_text(corpus_rel),
        corpus_dir: "lib/" ++ corpus_rel,
        root: wo_owned_text(root),
        target,
        abi_sha,
        slot: wo_store_dir(ctx) ++ slot_rel,
        install_slot: wo_store_install_dir(ctx) ++ slot_rel,
    }

// out/wo/<name>: the tree's copy every consumer reads.
pub fn wo_prefix(plan: &WoBundle) -> str:
    "out/wo/" ++ plan.name

// <store>/<name>/<target>-<abi_sha>/<name>: the published copy.
pub fn wo_store_prefix(plan: &WoBundle) -> str:
    plan.slot ++ "/" ++ plan.name

pub fn wo_build_target_name(plan: &WoBundle) -> str:
    plan.name ++ "-wo-build"

pub fn wo_group_target_name(plan: &WoBundle) -> str:
    plan.name ++ "-wo"

// Registers `<name>-wo-build`, the three installs and the `<name>-wo` group.
// `compiler` builds the bundle when the slot lacks this corpus: the stage
// whose ABI stamp is abi_sha (compiler_dep produces it).
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
    build_target = build_target.arg("abi-sha=" ++ plan.abi_sha)
    build_target = build_target.arg("slot=" ++ plan.slot)
    build_target = build_target.input(wo_owned_text(compiler))
    build_target = build_target.input("docs/with-abi.sha256")
    let corpus_files = wo_w_files(ctx.fs(), plan.corpus_dir)
    for fi in 0..corpus_files.len() as i32:
        build_target = build_target.input(wo_owned_text(corpus_files.get(fi as i64)))
    build_target = build_target.write_scope("out/wo")
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
        let ext = exts.get(ei as i64)
        let install_name = plan.name ++ "-wo-install-" ++ ext
        var install = target_new(.Install, wo_owned_text(install_name), fs_prefix ++ "." ++ ext).output(store_prefix ++ "." ++ ext)
        install = install.input(fs_prefix ++ "." ++ ext)
        install = install.arg("0644")
        install = install.dep(wo_owned_text(previous))
        graph = graph.add_target(install)
        group = group.dep(wo_owned_text(install_name))
        previous = install_name
    graph.add_target(group)

// "" when the slot holds a coherent bundle of this corpus, else why not.
fn wo_slot_status(fs: &ToolFs, store_prefix: &str, corpus_sha: &str, target: &str, abi_sha: &str) -> str:
    let exts: Vec[str] = Vec.new()
    exts.push("o")
    exts.push("wi")
    exts.push("manifest")
    for ei in 0..exts.len() as i32:
        let path = store_prefix ++ "." ++ exts.get(ei as i64)
        if not fs.host_exists(path):
            return "store lacks " ++ path
    let manifest = fs.host_read_text(store_prefix ++ ".manifest")
    if wo_manifest_field(manifest, "corpus-sha") != corpus_sha:
        return store_prefix ++ ".manifest was built from corpus " ++ wo_manifest_field(manifest, "corpus-sha") ++ ", the tree's is " ++ corpus_sha
    if wo_manifest_field(manifest, "target") != target or wo_manifest_field(manifest, "abi-sha") != abi_sha:
        return store_prefix ++ ".manifest names target " ++ wo_manifest_field(manifest, "target") ++ " and ABI " ++ wo_manifest_field(manifest, "abi-sha") ++ ", not this slot's"
    let wi_sha = wo_sha256_text(fs.host_read_text(store_prefix ++ ".wi"))
    if wo_manifest_field(manifest, "interface-sha") != wi_sha:
        return store_prefix ++ ".wi (sha256 " ++ wi_sha ++ ") is not the interface the stored manifest was built with"
    let object_sha = wo_sha256_text(fs.host_read_text(store_prefix ++ ".o"))
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
    let abi_sha = wo_arg_value(args, "abi-sha=")
    let slot = wo_arg_value(args, "slot=")
    let compiler = wo_arg_value(args, "compiler=")
    if name.len() == 0 or corpus.len() == 0 or corpus_dir.len() == 0 or root_path.len() == 0 or target.len() == 0 or abi_sha.len() != 64 or slot.len() == 0 or compiler.len() == 0:
        return wo_fail(ctx, "requires name=, corpus=, corpus-dir=, root=, target=, abi-sha=, slot= and compiler= arguments")
    let fs = ctx.fs()
    let root = ctx.project_info().project_root()
    let prefix = "out/wo/" ++ name
    let store_prefix = slot ++ "/" ++ name
    let capture_dir = "out/command/" ++ ctx.target_name()
    if fs.mkdir_all("out/wo") != 0 or fs.mkdir_all(capture_dir) != 0:
        return wo_fail(ctx, "could not create out/wo")
    let corpus_sha = wo_corpus_sha(fs, corpus_dir)
    let key = wo_sha256_text(corpus_sha ++ "|" ++ target ++ "|" ++ abi_sha)

    // Present: the slot holds this corpus, coherently — copy it in.
    let missing = wo_slot_status(fs, store_prefix, corpus_sha, target, abi_sha)
    if missing.len() == 0:
        let exts: Vec[str] = Vec.new()
        exts.push("o")
        exts.push("wi")
        exts.push("manifest")
        for ei in 0..exts.len() as i32:
            let ext = exts.get(ei as i64)
            if fs.write_text(prefix ++ "." ++ ext, fs.host_read_text(store_prefix ++ "." ++ ext)) != 0:
                return wo_fail(ctx, "could not copy " ++ store_prefix ++ "." ++ ext ++ " into out/wo")
        print("[" ++ ctx.target_name() ++ "] " ++ store_prefix ++ ".{o,wi,manifest} holds key " ++ key ++ " (corpus, target and ABI unchanged): compiled nothing")
        return 0
    print("[" ++ ctx.target_name() ++ "] " ++ missing ++ "; building " ++ name ++ " key " ++ key ++ " with " ++ compiler)

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

    let tmp = "out/wo/tmp/" ++ name
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
    // graph exactly — the second fingerprint pass, out of process.
    var check_args: Vec[str] = Vec.new()
    check_args.push(wo_abs(root, compiler))
    check_args.push("check")
    check_args.push(wo_abs(root, tmp_wi))
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
        return wo_fail(ctx, "the compiler names its target '" ++ wo_manifest_field(manifest, "target") ++ "' but build/wo.w planned '" ++ target ++ "' (wo_host_target and src/TargetSpec.w disagree)")
    if wo_manifest_field(manifest, "interface-sha") != wo_sha256_text(fs.read_text(tmp_wi)):
        return wo_fail(ctx, "the manifest's interface-sha is not the sha256 of " ++ tmp_wi)
    if wo_manifest_field(manifest, "fingerprint") != source_fp:
        return wo_fail(ctx, "the manifest's fingerprint is not the source fingerprint")
    manifest = manifest ++ "name " ++ name ++ "\n"
    manifest = manifest ++ "key " ++ key ++ "\n"
    manifest = manifest ++ "corpus-sha " ++ corpus_sha ++ "\n"
    manifest = manifest ++ "object-sha " ++ wo_sha256_text(fs.read_text(tmp_o)) ++ "\n"

    // Into out/wo: object, interface, then the manifest.
    if fs.rename(tmp_o, prefix ++ ".o") != 0:
        return wo_fail(ctx, "could not move " ++ tmp_o ++ " to " ++ prefix ++ ".o")
    if fs.rename(tmp_wi, prefix ++ ".wi") != 0:
        return wo_fail(ctx, "could not move " ++ tmp_wi ++ " to " ++ prefix ++ ".wi")
    if fs.write_text(prefix ++ ".manifest", manifest) != 0:
        return wo_fail(ctx, "could not write " ++ prefix ++ ".manifest")
    print("[" ++ ctx.target_name() ++ "] built " ++ prefix ++ ".{o,wi,manifest} key " ++ key)
    0
