// A green belongs to the sources (docs/decisions.md D49). `:last-green`
// publishes, keyed on what a battery tested — the git tree, the pinned seed
// that seeded the stage chain, the host — one line per identity in
// $WITH_GREEN_DIR, else ~/.local/with-green/green.tsv (build/retention.w
// writes it and reads it with the same rules). The driver's `:install-user`
// gate asks here whether the sources it is about to install already passed.

use compiler.Runtime
use BuildGraphSupport

extern fn with_sysinfo_os() -> str
extern fn with_sysinfo_arch() -> str

fn green_join(dir: &str, name: &str) -> str: if dir.ends_with("/"): dir ++ name else: dir ++ "/" ++ name

// What git prints for `args` run in `root`, or "" when git fails.
fn green_git_output(root: &str, args: &Vec[str], label: &str) -> str:
    let dir = green_join(root, "out/command/install-gate")
    if runtime_mkdir_p(dir) != 0: return ""
    let stdout_path = green_join(dir, label ++ ".stdout")
    var argv = build_graph_argv_append("", "git")
    for i in 0..args.len() as i32: argv = build_graph_argv_append(argv, args[i])
    if runtime_exec_argv_capture_cwd(argv, stdout_path, green_join(dir, label ++ ".stderr"), 60000, root) != 0: return ""
    runtime_read_file(stdout_path)

fn green_first_line(text: &str) -> str:
    for i in 0..text.len() as i32:
        if text[i] == '\n': return text.slice(0, i as i64)
    text.clone()

// The paths under docs/ that a battery lane reads: the specification
// (spec-inventory-check), the ABI record (abi-hash-check, the stage inputs)
// and the primer `with init` writes (selfhost).
pub const GREEN_DOCS_INPUTS: str = "docs/with-specification.md docs/with-abi.sha256 docs/with_for_ai.md"

/// The battery's inputs, as the text `git hash-object` identifies (D50: key
/// on what the output is made from). `top_level` is `git ls-tree HEAD`;
/// `docs_inputs` is `git ls-tree HEAD <GREEN_DOCS_INPUTS>`. A top-level entry
/// named `docs`, or a top-level `*.md` (CLAUDE.md, README.md, …), is prose no
/// lane compiles or tests, so it is left out: a docs-only commit keeps the
/// identity of the tree whose battery passed. build/retention.w applies the
/// same rule; the two must agree byte for byte.
pub fn green_identity_inputs(top_level: &str, docs_inputs: &str) -> str:
    var kept = ""
    for line in top_level.split("\n"):
        if line.len() == 0: continue
        let tab = line.find("\t")
        let path = if tab >= 0: line.slice(tab + 1, line.len()) else: line.clone()
        if path == "docs" or path.ends_with(".md"): continue
        kept = kept ++ line ++ "\n"
    kept ++ docs_inputs

// The identity of the inputs as committed: the git object name of the
// filtered listing, or "" when git fails.
fn green_inputs_identity(root: &str) -> str:
    let top_args: Vec[str] = Vec.new()
    top_args.push("ls-tree")
    top_args.push("HEAD")
    let top_level = green_git_output(root, &top_args, "ls-tree")
    if top_level.len() == 0: return ""
    var docs_args: Vec[str] = Vec.new()
    docs_args.push("ls-tree")
    docs_args.push("HEAD")
    for name in GREEN_DOCS_INPUTS.split(" "): docs_args.push(name.clone())
    let docs_inputs = green_git_output(root, &docs_args, "ls-tree-docs")
    let listing = green_join(green_join(root, "out/command/install-gate"), "green-inputs.txt")
    if runtime_write_file(listing, green_identity_inputs(top_level, docs_inputs)) != 0: return ""
    let hash_args: Vec[str] = Vec.new()
    hash_args.push("hash-object")
    hash_args.push(listing)
    green_first_line(green_git_output(root, &hash_args, "hash-object"))

// The tracked tree is as committed and nothing untracked could be a build
// input; an untracked path under examples/ is a user's own program.
fn green_worktree_is_clean(root: &str) -> bool:
    let args: Vec[str] = Vec.new()
    args.push("status")
    args.push("--porcelain")
    let status_lines = green_git_output(root, &args, "status").split("\n")
    for i in 0..status_lines.len() as i32:
        let line = status_lines.get(i)
        if line.len() > 0 and not line.starts_with("?? examples/"): return false
    true

/// The commit at which the sources under `root` were recorded green, or "":
/// the worktree is clean, its stage chain was seeded by a compiler seed.lock
/// pins, and the store has a green for this tree, that seed and this host.
pub fn green_by_source_identity(root: &str) -> str:
    let seed_input = runtime_read_file(green_join(root, "out/.build-state/seed-input.json"))
    let marker = "\"sha256\": \""
    let at = seed_input.find(marker)
    if at < 0 or at + marker.len() + 64 > seed_input.len(): return ""
    let seeded_by = seed_input.slice(at + marker.len(), at + marker.len() + 64)
    if not runtime_read_file(green_join(root, "seed.lock")).contains(seeded_by): return ""
    if not green_worktree_is_clean(root): return ""
    let tree = green_inputs_identity(root)
    if tree.len() < 40: return ""
    let identity = tree ++ "-" ++ seeded_by ++ "-" ++ with_sysinfo_os() ++ "_" ++ with_sysinfo_arch()
    let explicit = runtime_getenv("WITH_GREEN_DIR")
    let store_dir = if explicit.len() > 0: explicit else: runtime_getenv("HOME") ++ "/.local/with-green"
    let store_lines = runtime_read_file(green_join(store_dir, "green.tsv")).split("\n")
    for i in 0..store_lines.len() as i32:
        let line = store_lines.get(i)
        if line.starts_with(identity ++ "\t"):
            let fields = line.split("\t")
            return if fields.len() > 1: fields.get(1).clone() else: "recorded"
    ""
