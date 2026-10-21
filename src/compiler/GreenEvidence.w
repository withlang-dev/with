// A green belongs to the sources (2026-09-20-D49-green-evidence-is-keyed-on-what-was-tested-git-tree-pinned.md D49). `:last-green`
// publishes, keyed on what a battery tested — the git tree, the pinned seed
// that seeded the stage chain, the host — one line per identity in
// $WITH_GREEN_DIR, else ~/.local/with-green/green.tsv (build/retention.w
// writes it and reads it with the same rules). The driver's `:install-user`
// gate asks here whether the sources it is about to install already passed.

use compiler.Runtime
use BuildGraphSupport
use BuildGraphOps
use rt.rt_core


fn green_join(dir: &str, name: &str) -> str: if dir.ends_with("/"): dir ++ name else: dir ++ "/" ++ name

// The green store: $WITH_GREEN_DIR, else ~/.local/with-green.
fn green_store_dir() -> str:
    let explicit = runtime_getenv("WITH_GREEN_DIR")
    if explicit.len() > 0: explicit else: runtime_getenv("HOME") ++ "/.local/with-green"

// What git prints for `args` run in `root`, or "" when git fails.
fn green_git_output(root: &str, args: &List[str], label: &str) -> str:
    let dir = green_join(root, "out/command/install-gate")
    if runtime_mkdir_p(dir) != 0: return ""
    let stdout_path = green_join(dir, label ++ ".stdout")
    var argv = build_graph_argv_append("", "git")
    for i in 0..args.len(): argv = build_graph_argv_append(argv, args[i])
    if runtime_exec_argv_capture_cwd(argv, stdout_path, green_join(dir, label ++ ".stderr"), 60000, root) != 0: return ""
    runtime_read_file(stdout_path)

fn green_first_line(text: &str) -> str:
    for i in 0..text.len():
        if text[i] == '\n': return text.slice(0, i as i64)
    text.clone()

/// The battery's inputs, as the text `git hash-object` identifies (D50: key
/// on what the output is made from). `top_level` is `git ls-tree HEAD`. The
/// build measures software, not documents (Eric, 2026-09-21): the top-level
/// entry named `docs` and every top-level `*.md` (CLAUDE.md, README.md, …)
/// are left out, the specification included — a docs-only commit keeps the
/// identity of the tree whose battery passed. `benchmarks/goose` is
/// documentation only too (Eric, 2026-10-13): benchmarks-check measures
/// benchmarks/workloads/ and benchmarks/run.w, never goose, so the
/// benchmarks tree enters through its own listing (`bench_level`, `git
/// ls-tree HEAD:benchmarks`) with the goose entry left out.
/// build/retention.w applies the same rule; the two must agree byte for
/// byte.
fn green_identity_inputs(top_level: &str, bench_level: &str) -> str:
    var kept = ""
    for line in top_level.split("\n"):
        if line.len() == 0: continue
        let tab = line.find("\t")
        let path = if tab >= 0: line.slice(tab + 1, line.len()) else: line.clone()
        if path == "docs" or path.ends_with(".md"): continue
        if path == "benchmarks":
            for bench_line in bench_level.split("\n"):
                if bench_line.len() == 0: continue
                let bench_tab = bench_line.find("\t")
                if bench_tab >= 0 and bench_line.slice(bench_tab + 1, bench_line.len()) == "goose": continue
                kept = kept ++ bench_line ++ "\n"
            continue
        kept = kept ++ line ++ "\n"
    kept

// The identity of the inputs as committed: the git object name of the
// filtered listing, or "" when git fails.
fn green_inputs_identity(root: &str) -> str:
    let top_args: List[str] = List.new()
    top_args.push("ls-tree")
    top_args.push("HEAD")
    let top_level = green_git_output(root, &top_args, "ls-tree")
    if top_level.len() == 0: return ""
    let bench_args: List[str] = List.new()
    bench_args.push("ls-tree")
    bench_args.push("HEAD:benchmarks")
    let bench_level = green_git_output(root, bench_args, "ls-tree-benchmarks")
    if top_level.contains("\tbenchmarks\n") and bench_level.len() == 0: return ""
    let listing = green_join(green_join(root, "out/command/install-gate"), "green-inputs.txt")
    if runtime_write_file(listing, green_identity_inputs(top_level, bench_level)) != 0: return ""
    let hash_args: List[str] = List.new()
    hash_args.push("hash-object")
    hash_args.push(listing)
    green_first_line(green_git_output(root, &hash_args, "hash-object"))

/// A `git status --porcelain` line that names no build input: a document —
/// `docs/`, `benchmarks/goose/` and top-level `*.md` are outside the
/// identity (green_identity_inputs), so one that is untracked, modified or
/// deleted cannot dirty it (a modified handoff.md refused main's
/// install 2026-10-04; an untracked benchmarks/goose/ refused its reseed
/// 2026-10-13) — or a user's own untracked program under examples/. A
/// rename is judged an input: its line names two paths.
fn green_status_is_not_input(status_line: &str) -> bool:
    if status_line.len() < 4 or status_line.contains(" -> "): return false
    let path = status_line.slice(3, status_line.len())
    if path.starts_with("docs/") or path == "benchmarks/goose" or path.starts_with("benchmarks/goose/") or (path.ends_with(".md") and not path.contains("/")): return true
    status_line.starts_with("?? ") and path.starts_with("examples/")

// Every build input is as committed, and nothing untracked could be one.
fn green_worktree_is_clean(root: &str) -> bool:
    let args: List[str] = List.new()
    args.push("status")
    args.push("--porcelain")
    let status_lines = green_git_output(root, &args, "status").split("\n")
    for i in 0..status_lines.len():
        let line = status_lines[i]
        if line.len() > 0 and not green_status_is_not_input(line): return false
    true

/// The commit at which the sources under `root` were recorded green, or "":
/// the worktree is clean, its stage chain was seeded by a compiler seed.lock
/// pins, and the store has a green for this tree, that seed and this host.
fn green_by_source_identity(root: &str) -> str:
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
    let store_lines = runtime_read_file(green_join(green_store_dir(), "green.tsv")).split("\n")
    for i in 0..store_lines.len():
        let line = store_lines[i]
        if line.starts_with(identity ++ "\t"):
            let fields = line.split("\t")
            return if fields.len() > 1: fields[1].clone() else: "recorded"
    ""

// The ceremony census bar (tools/ceremony_census.w): the installed tree's
// counts, which every later tree is measured against. `:install-user` runs
// as the driver's fast path and never evaluates build.w's graph, so the
// bar's old graph route (a dep of install-user) never ran: from #702 on no
// reseed recorded it, the bar stayed at a hand-published 2026-10-08 copy,
// and the census gate measured trees against counts 12 days old. The
// candidate records it before anything is installed; a census that cannot
// record refuses the install, so a reseed never leaves a stale bar behind
// a new compiler.
fn green_publish_ceremony_bar(root: &str, compiler_path: &str, target_name: &str) -> i32:
    let out_dir = green_join(root, "out/ceremony-bar")
    if runtime_mkdir_p(out_dir) != 0:
        runtime_eprint(f"[{target_name}] error: could not create {out_dir}; nothing was installed")
        return 1
    let recorded = green_join(out_dir, "ceremony-bar.tsv")
    runtime_remove_file(recorded)
    var argv = build_graph_argv_append("", compiler_path)
    argv = build_graph_argv_append(argv, "run")
    argv = build_graph_argv_append(argv, green_join(root, "tools/ceremony_census.w"))
    argv = build_graph_argv_append(argv, "--compiler")
    argv = build_graph_argv_append(argv, compiler_path)
    argv = build_graph_argv_append(argv, "--record-bar")
    argv = build_graph_argv_append(argv, recorded)
    let err = green_join(out_dir, "census.stderr")
    let rc = runtime_exec_argv_capture_cwd(argv, green_join(out_dir, "census.stdout"), err, 1200000, root)
    let bar = runtime_read_file(recorded)
    if rc != 0 or bar.len() == 0:
        runtime_eprint(runtime_read_file(err))
        runtime_eprint(f"[{target_name}] error: the candidate could not record the ceremony census bar (exit {rc}, {bar.len()} bytes in {recorded}); nothing was installed")
        return 1
    let dest = green_join(green_store_dir(), "ceremony-bar.tsv")
    if build_graph_install_path(f"[{target_name}]", recorded, bar, dest, 0o644, "") != 0: return 1
    print(f"[{target_name}] {dest} <- this tree's ceremony census counts")
    0
