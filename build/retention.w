module build.retention

use std.build
use std.string.StringBuilder
use std.sysinfo
use build.seed
use build.compiler
fn retention_owned_text(s: &str): s ++ ""

const RET_SEED_KEEP: i32 = 5
const RET_RELEASE_VERSION_KEEP: i32 = 5

fn ret_fail(ctx: &ActionCtx, message: &str) -> i32:
    ctx.diagnostics().error(ctx.target_name() ++ ": " ++ message)
    1

fn ret_write_output_stamp(ctx: &ActionCtx) -> i32:
    let output = ctx.output()
    if output.len() == 0:
        return 0
    let fs = ctx.fs()
    let dir = ret_dirname(output)
    if fs.mkdir_all(dir) != 0:
        return ret_fail(ctx, "could not create output directory: " ++ dir)
    if fs.write_text(output, "ok\n") != 0:
        return ret_fail(ctx, "could not write output stamp: " ++ output)
    0

fn ret_join(left: &str, right: &str) -> str:
    if left.len() == 0:
        return retention_owned_text(right)
    if right.len() == 0:
        return retention_owned_text(left)
    if left.ends_with("/"):
        return left ++ right
    left ++ "/" ++ right

fn ret_abs(root: &str, path: &str) -> str:
    if path.len() > 0 and path[0] == 47:
        return retention_owned_text(path)
    // A Windows driver path (`C:/...`, WITH on the Windows lanes).
    if os() == "Windows" and path.len() >= 3 and path[1] == ':' and (path[2] == '/' or path[2] == '\\'):
        return retention_owned_text(path)
    ret_join(root, path)

fn ret_dirname(path: &str) -> str:
    var last_slash = -1
    for i in 0..path.len() as i32:
        if path[i] == 47:
            last_slash = i
    if last_slash < 0:
        return "."
    if last_slash == 0:
        return "/"
    path.slice(0, last_slash as i64)

fn ret_basename(path: &str) -> str:
    var last_slash = -1
    for i in 0..path.len() as i32:
        if path[i] == 47:
            last_slash = i
    if last_slash < 0:
        return retention_owned_text(path)
    path.slice((last_slash + 1) as i64, path.len())

fn ret_trim(text: &str) -> str:
    var start = 0
    var end = text.len() as i32
    while start < end:
        let ch = text[start]
        if ch != 9 and ch != 10 and ch != 13 and ch != 32:
            break
        start = start + 1
    while end > start:
        let ch = text[(end - 1)]
        if ch != 9 and ch != 10 and ch != 13 and ch != 32:
            break
        end = end - 1
    text.slice(start as i64, end as i64)

fn ret_first_line(text: &str) -> str:
    var end = text.len() as i32
    for i in 0..text.len() as i32:
        let ch = text[i]
        if ch == 10 or ch == 13:
            end = i
            break
    ret_trim(text.slice(0, end as i64))

fn ret_split_lines(text: &str) -> Vec[str]:
    let out: Vec[str] = Vec.new()
    var start = 0
    for i in 0..text.len() as i32:
        let ch = text[i]
        if ch == 10 or ch == 13:
            let line = ret_trim(text.slice(start as i64, i as i64))
            if line.len() > 0:
                out.push(line)
            start = i + 1
    if start < text.len() as i32:
        let line = ret_trim(text.slice(start as i64, text.len()))
        if line.len() > 0:
            out.push(line)
    out

fn ret_json_escape(text: &str) -> str:
    var out = ""
    for i in 0..text.len() as i32:
        let ch = text[i]
        if ch == 34:
            out = out ++ "\\\""
        else if ch == 92:
            out = out ++ "\\\\"
        else if ch == 10:
            out = out ++ "\\n"
        else if ch == 13:
            out = out ++ "\\r"
        else if ch == 9:
            out = out ++ "\\t"
        else:
            out = out ++ text.slice(i as i64, (i + 1) as i64)
    out

fn ret_safe_label(text: &str) -> str:
    var out = ""
    for i in 0..text.len() as i32:
        let ch = text[i]
        let keep = (ch >= 48 and ch <= 57) or (ch >= 65 and ch <= 90) or (ch >= 97 and ch <= 122) or ch == 45 or ch == 46 or ch == 95
        if keep:
            out = out ++ text.slice(i as i64, (i + 1) as i64)
        else:
            out = out ++ "_"
    if out.len() == 0:
        return "unknown"
    out

fn ret_short(text: &str, n: i32) -> str:
    if text.len() <= n:
        return retention_owned_text(text)
    text.slice(0, n as i64)

fn ret_run_first_line(ctx: &ActionCtx, label: &str, args: &Vec[str], timeout_ms: i32) -> str:
    let fs = ctx.fs()
    let root = ctx.project_info().project_root()
    let dir = ret_join("out/command", ctx.target_name())
    if fs.mkdir_all(dir) != 0:
        return ""
    let stdout_path = ret_join(dir, label ++ ".stdout")
    let stderr_path = ret_join(dir, label ++ ".stderr")
    let result = ctx.process_runner().run_capture(args, ret_abs(root, stdout_path), ret_abs(root, stderr_path), timeout_ms)
    if result.rc != 0:
        return ""
    ret_first_line(result.stdout)

fn ret_run_lines(ctx: &ActionCtx, label: &str, args: &Vec[str], timeout_ms: i32) -> Vec[str]:
    let fs = ctx.fs()
    let root = ctx.project_info().project_root()
    let dir = ret_join("out/command", ctx.target_name())
    if fs.mkdir_all(dir) != 0:
        return Vec.new()
    let stdout_path = ret_join(dir, label ++ ".stdout")
    let stderr_path = ret_join(dir, label ++ ".stderr")
    let result = ctx.process_runner().run_capture(args, ret_abs(root, stdout_path), ret_abs(root, stderr_path), timeout_ms)
    if result.rc != 0:
        return Vec.new()
    ret_split_lines(result.stdout)

fn ret_run_status(ctx: &ActionCtx, label: &str, args: &Vec[str], timeout_ms: i32) -> i32:
    let fs = ctx.fs()
    let root = ctx.project_info().project_root()
    let dir = ret_join("out/command", ctx.target_name())
    if fs.mkdir_all(dir) != 0:
        return 1
    let stdout_path = ret_join(dir, label ++ ".stdout")
    let stderr_path = ret_join(dir, label ++ ".stderr")
    let result = ctx.process_runner().run_capture(args, ret_abs(root, stdout_path), ret_abs(root, stderr_path), timeout_ms)
    if result.rc != 0:
        ctx.diagnostics().error(ctx.target_name() ++ ": command '" ++ label ++ f"' failed with exit code {result.rc}; stdout=" ++ stdout_path ++ " stderr=" ++ stderr_path)
    result.rc

fn ret_sha256_tool(root: &str) -> str:
    let suffix = if os() == "Windows": ".exe" else: ""
    ret_abs(root, "out/bin/with-sha256" ++ suffix)

fn ret_sha256_file(ctx: &ActionCtx, label: &str, path: &str) -> str:
    let root = ctx.project_info().project_root()
    let target_path = ret_abs(root, path)
    let args: Vec[str] = Vec.new()
    args.push(ret_sha256_tool(root))
    args.push(target_path)
    let line = ret_run_first_line(ctx, label ++ "-sha256", args, 120000)
    if line.len() >= 64:
        return line.slice(0, 64)
    ""

fn ret_sha256_text(ctx: &ActionCtx, label: &str, text: &str) -> str:
    let fs = ctx.fs()
    let dir = ret_join("out/command", ctx.target_name())
    if fs.mkdir_all(dir) != 0:
        return ""
    let safe_label = ret_safe_label(label)
    let path = ret_join(dir, safe_label ++ ".txt")
    if fs.write_text(path, text) != 0:
        return ""
    let result = ret_sha256_file(ctx, safe_label, path)
    let _remove = fs.remove_file(path)
    result

fn ret_str_compare(a: &str, b: &str) -> i32:
    let min_len = if a.len() < b.len(): a.len() else: b.len()
    for i in 0..min_len as i32:
        let ac = a[i] as i32
        let bc = b[i] as i32
        if ac != bc:
            return ac - bc
    if a.len() == b.len():
        return 0
    if a.len() < b.len():
        return -1
    1

fn ret_sorted_strings(items: Vec[str]) -> Vec[str]:
    var sorted: Vec[str] = Vec.new()
    for i in 0..items.len() as i32:
        let item = items[i]
        var inserted = false
        let next: Vec[str] = Vec.new()
        for j in 0..sorted.len() as i32:
            let existing = sorted[j]
            if not inserted and ret_str_compare(item, existing) < 0:
                next.push(retention_owned_text(item))
                inserted = true
            next.push(retention_owned_text(existing))
        if not inserted:
            next.push(retention_owned_text(item))
        sorted = next
    sorted

fn ret_release_version_component(version: &str, part: i32) -> i32:
    var start = 0
    if version.starts_with("v"):
        start = 1
    var current = 0
    while current < part:
        var dot = -1
        for i in start..version.len() as i32:
            if version[i] == 46:
                dot = i
                break
        if dot < 0:
            return -1
        start = dot + 1
        current = current + 1
    var end = version.len() as i32
    for i in start..version.len() as i32:
        if version[i] == 46:
            end = i
            break
    if end <= start:
        return -1
    var value = 0
    for i in start..end:
        let ch = version[i]
        if ch < 48 or ch > 57:
            return -1
        value = value * 10 + (ch - 48)
    value

fn ret_release_version_compare(a: &str, b: &str) -> i32:
    let a_major = ret_release_version_component(a, 0)
    let a_minor = ret_release_version_component(a, 1)
    let a_patch = ret_release_version_component(a, 2)
    let b_major = ret_release_version_component(b, 0)
    let b_minor = ret_release_version_component(b, 1)
    let b_patch = ret_release_version_component(b, 2)
    if a_major >= 0 and a_minor >= 0 and a_patch >= 0 and b_major >= 0 and b_minor >= 0 and b_patch >= 0:
        if a_major != b_major:
            return a_major - b_major
        if a_minor != b_minor:
            return a_minor - b_minor
        if a_patch != b_patch:
            return a_patch - b_patch
        return 0
    ret_str_compare(a, b)

fn ret_sorted_release_versions(items: Vec[str]) -> Vec[str]:
    var sorted: Vec[str] = Vec.new()
    for i in 0..items.len() as i32:
        let item = items[i]
        var inserted = false
        let next: Vec[str] = Vec.new()
        for j in 0..sorted.len() as i32:
            let existing = sorted[j]
            if not inserted and ret_release_version_compare(item, existing) < 0:
                next.push(retention_owned_text(item))
                inserted = true
            next.push(retention_owned_text(existing))
        if not inserted:
            next.push(retention_owned_text(item))
        sorted = next
    sorted

fn ret_direct_w_files(fs: &ToolFs, dir: &str) -> Vec[str]:
    let out: Vec[str] = Vec.new()
    let files = fs.list_files(dir)
    for i in 0..files.len() as i32:
        let path = files[i]
        if path.ends_with(".w") and ret_dirname(path) == dir:
            out.push(retention_owned_text(path))
    ret_sorted_strings(out)

fn ret_sha256_hex_list(ctx: &ActionCtx, label: &str, files: &Vec[str]) -> Vec[str]:
    let out: Vec[str] = Vec.new()
    let manifest = ret_sha256_files_manifest(ctx, label, files)
    if manifest.len() == 0:
        return out
    let lines = manifest.split("\n")
    for i in 0..lines.len() as i32:
        let line = lines[i]
        if line.len() >= 64:
            out.push(line.slice(0, 64))
    out

fn ret_expected_test_marker(ctx: &ActionCtx, target_name: &str, entry: &str) -> str:
    let fs = ctx.fs()
    let compiler_path = ret_release_compiler_path()
    // Mirrors BuildGraphCache.build_cache_test_success_manifest v2: the
    // compiler and every test file are keyed by content sha256, so stale
    // evidence cannot survive a compiler rebuild (the v1 marker recorded
    // the compiler by path only).
    var text = "v2\n"
    text = text ++ "target:" ++ target_name ++ "\n"
    text = text ++ "kind:2\n"
    text = text ++ "entry:" ++ entry ++ "\n"
    text = text ++ "output:\n"
    text = text ++ "opt:0\n"
    text = text ++ "target-kind:0\n"
    text = text ++ "arg:compiler=" ++ compiler_path ++ "\n"
    text = text ++ "compiler:" ++ compiler_path ++ "\n"
    let comp_files: Vec[str] = Vec.new()
    comp_files.push(compiler_path)
    let comp_hexes = ret_sha256_hex_list(ctx, ret_safe_label(target_name) ++ "-marker-compiler", comp_files)
    if comp_hexes.len() as i32 != 1:
        ctx.diagnostics().error(ctx.target_name() ++ ": could not hash test compiler for marker " ++ target_name)
        return ""
    text = text ++ "compiler-sha256:" ++ comp_hexes.get(0) ++ "\n"
    let files = ret_direct_w_files(fs, ret_dirname(entry))
    let file_hexes = ret_sha256_hex_list(ctx, ret_safe_label(target_name) ++ "-marker-files", files)
    if file_hexes.len() != files.len():
        ctx.diagnostics().error(ctx.target_name() ++ ": could not hash test files for marker " ++ target_name)
        return ""
    for i in 0..files.len() as i32:
        text = text ++ "file:" ++ files[i] ++ ":" ++ file_hexes[i] ++ "\n"
    text

fn ret_host_bin(path: &str) -> str:
    if os() == "Windows":
        return path ++ ".exe"
    retention_owned_text(path)

fn ret_release_compiler_path() -> str:
    ret_host_bin("out/release/bin/with")

fn ret_stage_fixpoint_path(name: &str) -> str:
    "out/stage/bin/" ++ name

fn ret_append_test_marker(ctx: &ActionCtx, combined: &str, target_name: &str, entry: &str) -> str:
    let marker_path = "out/.build-state/" ++ target_name ++ ".test-pass"
    let fs = ctx.fs()
    let actual = if fs.exists(marker_path): fs.read_text(marker_path) else: ""
    if actual.len() == 0:
        ctx.diagnostics().error(ctx.target_name() ++ ": missing test pass marker " ++ marker_path ++ "; run `with build :test`")
        return ""
    let expected = ret_expected_test_marker(ctx, target_name, entry)
    if actual != expected:
        ctx.diagnostics().error(ctx.target_name() ++ ": stale test pass marker " ++ marker_path ++ "; run `with build :test`")
        return ""
    combined ++ "marker:" ++ target_name ++ "\n" ++ actual

fn ret_append_state_file(ctx: &ActionCtx, combined: &str, target_name: &str) -> str:
    let state_path = "out/.build-state/" ++ target_name ++ ".state"
    let state = if ctx.fs().exists(state_path): ctx.fs().read_text(state_path) else: ""
    if state.len() == 0:
        ctx.diagnostics().error(ctx.target_name() ++ ": missing build state " ++ state_path ++ "; run `with build :test`")
        return ""
    combined ++ "state:" ++ target_name ++ "\n" ++ state ++ "\n"

fn ret_sha256_files_manifest(ctx: &ActionCtx, label: &str, files: &Vec[str]) -> str:
    if files.len() == 0:
        return ""
    // #679: this runs under the comptime action evaluator, where the old
    // `out = out ++ line` accumulation over ~2000 files was quadratic
    // INTERPRETED copying and 100-file batches meant ~20 spawn round-trips
    // — 77s of test-green wall for ~0.2s of native hashing. StringBuilder
    // + 250-file batches keep it linear and the spawns rare.
    var out = StringBuilder.new()
    var batch: Vec[str] = Vec.new()
    var batch_names: Vec[str] = Vec.new()
    var batch_index = 0
    let root = ctx.project_info().project_root()
    for i in 0..files.len() as i32:
        let file = files[i]
        batch.push(ret_abs(root, file))
        batch_names.push(retention_owned_text(file))
        let last = i + 1 == files.len() as i32
        // argv is capped at 255 entries by the runtime spawn path — stay under
        // it (tool + slack) while keeping spawns rare.
        if batch.len() as i32 >= 250 or last:
            let args: Vec[str] = Vec.new()
            args.push(ret_sha256_tool(root))
            for bi in 0..batch.len() as i32:
                args.push(retention_owned_text(batch[bi]))
            let lines = ret_run_lines(ctx, label ++ "-" ++ f"{batch_index}" ++ "-sha256", args, 120000)
            if lines.len() != batch.len():
                return ""
            for li in 0..lines.len() as i32:
                let line = lines[li]
                if line.len() < 64:
                    return ""
                out.push_str(line.slice(0, 64))
                out.push_str("  ")
                out.push_str(batch_names[li])
                out.push_str("\n")
            batch = Vec.new()
            batch_names = Vec.new()
            batch_index = batch_index + 1
    out.to_str()

fn ret_append_file_hashes(combined: &str, ctx: &ActionCtx, label: &str, files: &Vec[str]) -> str:
    let manifest = ret_sha256_files_manifest(ctx, label, files)
    if files.len() > 0 and manifest.len() == 0:
        ctx.diagnostics().error(ctx.target_name() ++ ": could not hash " ++ label ++ " files")
        return ""
    combined ++ "files:" ++ label ++ "\n" ++ manifest

fn ret_build_driver_sources_manifest(ctx: &ActionCtx) -> str:
    let fs = ctx.fs()
    let files: Vec[str] = Vec.new()
    files.push("build.w")
    let build_files = ret_sorted_strings(fs.list_files("build"))
    for i in 0..build_files.len() as i32:
        let path = build_files[i]
        if path.ends_with(".w"):
            files.push(retention_owned_text(path))
    files.push("src/main.w")
    files.push("src/BuildGraphTests.w")
    files.push("src/BuildGraphCache.w")
    ret_append_file_hashes("", ctx, "build-driver", files)

fn ret_append_test_file_hashes(combined: &str, ctx: &ActionCtx, entry: &str) -> str:
    let dir = ret_dirname(entry)
    let files = ret_direct_w_files(ctx.fs(), dir)
    if files.len() == 0:
        ctx.diagnostics().error(ctx.target_name() ++ ": no test source files found for " ++ entry)
        return ""
    let manifest = ret_sha256_files_manifest(ctx, ret_safe_label(entry) ++ "-files", files)
    if manifest.len() == 0:
        ctx.diagnostics().error(ctx.target_name() ++ ": could not hash " ++ entry ++ " files")
        return ""
    combined ++ "files:" ++ entry ++ "\n" ++ manifest

fn ret_test_green_fingerprint(ctx: &ActionCtx) -> str:
    var combined = ret_build_driver_sources_manifest(ctx)
    if combined.len() == 0: return ""
    combined = ret_append_test_marker(ctx, combined, "behavior-tests", "test/behavior/*.w")
    if combined.len() == 0: return ""
    combined = ret_append_test_file_hashes(combined, ctx, "test/behavior/*.w")
    if combined.len() == 0: return ""
    combined = ret_append_test_marker(ctx, combined, "native-compile-error-tests", "test/compile_errors/*.w")
    if combined.len() == 0: return ""
    combined = ret_append_test_file_hashes(combined, ctx, "test/compile_errors/*.w")
    if combined.len() == 0: return ""
    combined = ret_append_test_marker(ctx, combined, "native-codegen-tests", "test/codegen/*.w")
    if combined.len() == 0: return ""
    combined = ret_append_test_file_hashes(combined, ctx, "test/codegen/*.w")
    if combined.len() == 0: return ""
    combined = ret_append_test_marker(ctx, combined, "native-spec-tests", "test/spec/*.w")
    if combined.len() == 0: return ""
    combined = ret_append_test_file_hashes(combined, ctx, "test/spec/*.w")
    if combined.len() == 0: return ""
    combined = ret_append_test_marker(ctx, combined, "native-phase-tests", "test/phase/*.w")
    if combined.len() == 0: return ""
    combined = ret_append_test_file_hashes(combined, ctx, "test/phase/*.w")
    if combined.len() == 0: return ""
    combined = ret_append_state_file(ctx, combined, "selfcheck")
    if combined.len() == 0: return ""
    combined = ret_append_state_file(ctx, combined, "cli-selfhost-smoke-tests")
    if combined.len() == 0: return ""
    combined = ret_append_state_file(ctx, combined, "cli-selfhost-one-liner-tests")
    if combined.len() == 0: return ""
    combined = ret_append_state_file(ctx, combined, "cli-selfhost-object-symbol-tests")
    if combined.len() == 0: return ""
    combined = ret_append_state_file(ctx, combined, "cli-selfhost-build-w-tests")
    if combined.len() == 0: return ""
    combined = ret_append_state_file(ctx, combined, "build-helper-programs")
    if combined.len() == 0: return ""
    combined = ret_append_state_file(ctx, combined, "cli-selfhost-project-tests")
    if combined.len() == 0: return ""
    combined = ret_append_state_file(ctx, combined, "cli-selfhost-edge-tests")
    if combined.len() == 0: return ""
    combined = ret_append_state_file(ctx, combined, "cli-selfhost-parallel-tests")
    if combined.len() == 0: return ""
    combined = ret_append_state_file(ctx, combined, "c-migrator-basic-tests")
    if combined.len() == 0: return ""
    combined = ret_append_state_file(ctx, combined, "c-migrator-core-tests")
    if combined.len() == 0: return ""
    combined = ret_append_state_file(ctx, combined, "issue61-regression")
    if combined.len() == 0: return ""
    combined = ret_append_state_file(ctx, combined, "embedded-runtime-regression")
    if combined.len() == 0: return ""
    combined = ret_append_state_file(ctx, combined, "emit-c-smoke")
    if combined.len() == 0: return ""
    ret_sha256_text(ctx, "test-green-inputs", combined)

fn ret_git_commit(ctx: &ActionCtx) -> str:
    let args: Vec[str] = Vec.new()
    args.push("git")
    args.push("rev-parse")
    args.push("HEAD")
    ret_run_first_line(ctx, "git-head", args, 30000)

// ── green evidence is keyed on what was tested (Eric, 2026-09-20) ───────────
// The compiler binary names a commit (its version ends in -g<hash>) and its
// debug info names the worktree, so a squash-merge of a tested tree, or a
// battery run in a staging worktree, produced a "different" compiler and the
// whole battery ran again over byte-identical sources. What was tested is the
// inputs: the git tree, the pinned seed that drove and seeded the chain, and
// the host. A green for that identity is published to a store shared by every
// worktree ($WITH_GREEN_DIR, else ~/.local/with-green), one line per identity:
//   identity <TAB> git commit <TAB> compiler version <TAB> driver sha256
// A dirty worktree has no identity: uncommitted edits never borrow a green.

pub fn ret_green_store_path() -> str:
    let explicit = env("WITH_GREEN_DIR")
    let dir = if explicit.len() > 0: explicit else: env("HOME") ++ "/.local/with-green"
    dir ++ "/green.tsv"

/// An untracked path that is not a build input: a user's own program under
/// examples/, or a document — `docs/` and top-level `*.md` are outside the
/// identity, so an untracked one cannot dirty it. Mirrors
/// GreenEvidence.green_untracked_is_not_input; the two must agree.
fn ret_untracked_is_not_input(status_line: &str) -> bool:
    if not status_line.starts_with("?? "): return false
    let path = status_line.slice(3, status_line.len())
    path.starts_with("examples/") or path.starts_with("docs/") or (path.ends_with(".md") and not path.contains("/"))

/// The tracked tree is as committed, and nothing untracked could be a build
/// input.
fn ret_worktree_is_clean(ctx: &ActionCtx) -> bool:
    let args: Vec[str] = Vec.new()
    args.push("git")
    args.push("status")
    args.push("--porcelain")
    let lines = ret_run_lines(ctx, "git-status", args, 60000)
    for i in 0..lines.len() as i32:
        let line = lines.get(i)
        if line.len() == 0: continue
        if ret_untracked_is_not_input(line): continue
        return false
    true

/// `<tree>-<driver sha256>-<os>_<arch>`, or "" for a dirty worktree or a
/// tree git cannot name.
// The battery's inputs as the text `git hash-object` identifies (D50): the
// top-level `git ls-tree HEAD` without the `docs` entry and without top-level
// `*.md` files. The build measures software, not documents (Eric,
// 2026-09-21), so the specification is not an input either; a docs-only
// commit keeps the identity of the tree whose battery passed. Mirrors
// GreenEvidence.green_identity_inputs byte for byte.
fn ret_green_identity_inputs(top_level: &str) -> str:
    var kept = ""
    for line in top_level.split("\n"):
        if line.len() == 0: continue
        let tab = line.find("\t")
        let path = if tab >= 0: line.slice(tab + 1, line.len()) else: line.clone()
        if path == "docs" or path.ends_with(".md"): continue
        kept = kept ++ line ++ "\n"
    kept

fn ret_run_all(ctx: &ActionCtx, label: &str, args: &Vec[str], timeout_ms: i32) -> str:
    let fs = ctx.fs()
    let root = ctx.project_info().project_root()
    let dir = ret_join("out/command", ctx.target_name())
    if fs.mkdir_all(dir) != 0: return ""
    let result = ctx.process_runner().run_capture(args, ret_abs(root, ret_join(dir, label ++ ".stdout")), ret_abs(root, ret_join(dir, label ++ ".stderr")), timeout_ms)
    if result.rc != 0: return ""
    result.stdout.clone()

pub fn ret_source_identity(ctx: &ActionCtx, driver_sha: &str) -> str:
    if driver_sha.len() != 64 or not ret_worktree_is_clean(ctx): return ""
    let top_args: Vec[str] = Vec.new()
    top_args.push("git")
    top_args.push("ls-tree")
    top_args.push("HEAD")
    let top_level = ret_run_all(ctx, "git-ls-tree", top_args, 30000)
    if top_level.len() == 0: return ""
    let listing = ret_join(ret_join("out/command", ctx.target_name()), "green-inputs.txt")
    if ctx.fs().write_text(listing, ret_green_identity_inputs(top_level)) != 0: return ""
    let hash_args: Vec[str] = Vec.new()
    hash_args.push("git")
    hash_args.push("hash-object")
    hash_args.push(listing)
    let tree = ret_run_first_line(ctx, "git-hash-object", hash_args, 30000)
    if tree.len() < 40: return ""
    tree ++ "-" ++ driver_sha ++ "-" ++ os() ++ "_" ++ arch()

/// The store line for `identity`, or "".
fn ret_green_store_line(store: &str, identity: &str) -> str:
    if identity.len() == 0: return ""
    let lines = store.split("\n")
    for i in 0..lines.len() as i32:
        let line = lines.get(i)
        if line.starts_with(identity ++ "\t"): return line.clone()
    ""

fn ret_compiler_version(ctx: &ActionCtx, compiler_path: &str) -> str:
    let root = ctx.project_info().project_root()
    let args: Vec[str] = Vec.new()
    args.push(ret_abs(root, compiler_path))
    args.push("version")
    ret_run_first_line(ctx, "compiler-version", args, 60000)

fn ret_vec_contains(items: &Vec[str], item: &str) -> bool:
    for i in 0..items.len() as i32:
        if items[i] == item:
            return true
    false

fn ret_add_unique(items: Vec[str], item: &str) -> Vec[str]:
    let out: Vec[str] = Vec.new()
    var found = item.len() == 0
    for i in 0..items.len() as i32:
        let existing = items[i]
        if existing == item:
            found = true
        out.push(retention_owned_text(existing))
    if not found:
        out.push(retention_owned_text(item))
    out

fn ret_manifest_lines_without(manifest: Vec[str], skip: &str) -> Vec[str]:
    let out: Vec[str] = Vec.new()
    for i in 0..manifest.len() as i32:
        let item = manifest[i]
        if item != skip:
            out.push(retention_owned_text(item))
    out

fn ret_join_lines(items: Vec[str]) -> str:
    var out = ""
    for i in 0..items.len() as i32:
        out = out ++ items[i] ++ "\n"
    out

fn ret_seed_manifest_entries(fs: &ToolFs) -> Vec[str]:
    if not fs.exists("out/seed-archive/manifest.tsv"):
        return Vec.new()
    ret_split_lines(fs.read_text("out/seed-archive/manifest.tsv"))

fn ret_archive_verified_seed(ctx: &ActionCtx, version: &str, commit: &str, sha256: &str) -> i32:
    let fs = ctx.fs()
    if fs.mkdir_all("out/seed-archive") != 0:
        return ret_fail(ctx, "could not create out/seed-archive")
    let archive = "out/seed-archive/with-" ++ ret_safe_label(version) ++ "-" ++ ret_short(commit, 12) ++ "-" ++ ret_short(sha256, 12)
    if not fs.exists(archive):
        if fs.copy_file(ret_release_compiler_path(), archive) != 0:
            return ret_fail(ctx, "could not archive verified seed: " ++ archive)
        if fs.chmod(archive, 493) != 0:
            return ret_fail(ctx, "could not chmod archived seed: " ++ archive)
    var entries = ret_manifest_lines_without(ret_seed_manifest_entries(fs), archive)
    entries.push(archive)
    while entries.len() as i32 > RET_SEED_KEEP:
        let remove_path = entries.get(0)
        if fs.exists(remove_path):
            let _remove_old_seed = fs.remove_file(remove_path)
        let trimmed: Vec[str] = Vec.new()
        for i in 1..entries.len() as i32:
            trimmed.push(retention_owned_text(entries[i]))
        entries = trimmed
    if fs.write_text("out/seed-archive/manifest.tsv", ret_join_lines(entries)) != 0:
        return ret_fail(ctx, "could not write out/seed-archive/manifest.tsv")
    0

// ── The pinned driver ───────────────────────────────────────────────────────
// CI drives `build` and `:test` with the seed pinned in seed.lock, so every
// action body here is comptime-evaluated by that released compiler. A battery
// driven by anything newer proves nothing about CI (#1143: an action used
// `<` on strings; the fresh driver accepted it, the pinned seed did not), so
// `seed-driver`, `test-green` and `last-green` refuse any other driver — the
// Rust and Go rule: the pinned stage0 builds `bootstrap`, `GOROOT_BOOTSTRAP`
// builds `cmd/dist`, and a newer compiler is refused for that job.
//
// The driver is whatever the graph resolves `"seed"` to (WITH, then `with`
// on PATH, then src/main): the evaluator exports nothing about itself, and
// the driver seeds the stage chain through that same chain. On POSIX the
// action's process ancestry is checked too, so `WITH=src/main with build`
// (the pinned seed compiles, the fresh compiler evaluates build.w) is
// refused as well.

/// The host seed asset the target was registered with (release_asset_for_host).
fn ret_seed_asset_arg(ctx: &ActionCtx) -> str:
    let args = ctx.args()
    if args.len() > 0: args.get(0).clone() else: ""

/// The pinned digest for `asset` when the driving compiler is that seed;
/// "" after a diagnostic naming the driver, its digest and the fix.
fn ret_require_pinned_driver(ctx: &ActionCtx, asset: &str) -> str:
    let fs = ctx.fs()
    let lock = seed_lock_read(fs)
    if lock.len() == 0:
        let _ = ret_fail(ctx, "seed.lock is missing: the tree has no pinned seed")
        return ""
    if asset.len() == 0:
        let _ = ret_fail(ctx, "no host seed asset (release_asset_for_host) for " ++ os() ++ "/" ++ arch())
        return ""
    let expected = seed_lock_value(lock, asset)
    let version = seed_lock_version_for(lock, asset)
    if version.len() == 0 or expected.len() != 64:
        let _ = ret_fail(ctx, "seed.lock has no version or no 64-hex digest for " ++ asset)
        return ""
    let capture_dir = ret_join("out/command", ctx.target_name())
    if fs.mkdir_all(capture_dir) != 0:
        let _ = ret_fail(ctx, "could not create " ++ capture_dir)
        return ""
    let driver_arg = compiler_resolve_seed(ctx)
    let driver = compiler_resolve_command_file(ctx, capture_dir, driver_arg)
    let actual = ret_sha256_file(ctx, "driver", driver)
    if actual.len() == 0:
        let _ = ret_fail(ctx, "could not hash the driving compiler: " ++ driver)
        return ""
    if actual != expected:
        let _ = ret_fail(ctx, ret_pinned_driver_fix("the driving compiler " ++ driver ++ " (sha256 " ++ actual ++ ") is not the pinned seed " ++ version ++ " (" ++ expected ++ ")"))
        return ""
    if ret_driver_ancestry_verdict(ctx, expected, version) != 0:
        return ""
    expected

fn ret_pinned_driver_fix(problem: &str) -> str:
    problem ++ "; the battery is driven by the pinned seed, as CI is: `with build :seed` (once per seed.lock bump), then `WITH=$PWD/src/main src/main build :test`"

/// POSIX: the executables of this action's ancestor processes (the runner or
/// the evaluating driver, then its parents). One of them must be the pinned
/// seed; when none can be resolved to a file the check reports itself
/// unverified instead of failing.
fn ret_driver_ancestry_verdict(ctx: &ActionCtx, expected: &str, version: &str) -> i32:
    if os() == "Windows":
        return 0
    let fs = ctx.fs()
    let root = ctx.project_info().project_root()
    let capture_dir = ret_join("out/command", ctx.target_name())
    let probe: Vec[str] = Vec.new()
    probe.push("sh")
    probe.push("-c")
    probe.push("p=$PPID; n=0; while [ \"$p\" -gt 1 ] && [ $n -lt 8 ]; do e=$(readlink /proc/$p/exe 2>/dev/null || ps -o comm= -p $p 2>/dev/null); echo \"$e\"; p=$(ps -o ppid= -p $p 2>/dev/null | tr -d ' '); [ -n \"$p\" ] || break; n=$((n+1)); done")
    let ancestors = ret_run_lines(ctx, "driver-ancestry", probe, 30000)
    var seen: Vec[str] = Vec.new()
    for i in 0..ancestors.len() as i32:
        var exe: str = ancestors.get(i).clone()
        if exe.len() == 0: continue
        if exe.starts_with("-"): exe = exe.slice(1, exe.len())
        // A bare name is a PATH lookup (`with build`): resolve it the way the
        // shell did, so the installed compiler is named, not skipped.
        if not exe.contains("/"):
            let which: Vec[str] = Vec.new()
            which.push("which")
            which.push(exe.clone())
            exe = ret_run_first_line(ctx, f"driver-ancestry-which-{i}", which, 30000)
            if exe.len() == 0: continue
        let path = ret_abs(root, exe)
        if not fs.host_exists(path): continue
        let sha = ret_sha256_file(ctx, f"driver-ancestry-{i}", path)
        if sha == expected:
            return 0
        if sha.len() > 0: seen.push(path)
    if seen.len() == 0:
        print("[" ++ ctx.target_name() ++ "] driver identity unverified: no ancestor process resolves to a file (probe: " ++ ret_join(capture_dir, "driver-ancestry.stdout") ++ ")")
        return 0
    var message = "no ancestor process of this action is the pinned seed " ++ version ++ "; the build system is being evaluated by another compiler:"
    for i in 0..seen.len() as i32: message = message ++ "\n  " ++ seen.get(i)
    ret_fail(ctx, ret_pinned_driver_fix(message))

/// `with build :seed-driver` (arg: host seed asset). Fails fast, first in
/// `:test`, when the driver is not the pinned seed or a workflow pin
/// disagrees with seed.lock.
pub fn run_seed_driver_action(ctx: ActionCtx) -> i32:
    let asset = ret_seed_asset_arg(ctx)
    let expected = ret_require_pinned_driver(ctx, asset)
    if expected.len() == 0:
        return 1
    let lock = seed_lock_read(ctx.fs())
    let drift = seed_lock_workflow_drift(ctx.fs(), lock)
    if drift.len() > 0:
        var message = "these workflow seed pins disagree with seed.lock (" ++ seed_lock_version_for(lock, asset) ++ "); `with run tools/bump_seed_pins.w` rewrites them:"
        for i in 0..drift.len() as i32: message = message ++ "\n  " ++ drift.get(i)
        return ret_fail(ctx, message)
    print("[seed-driver] the driver is the pinned seed " ++ seed_lock_version_for(lock, asset) ++ "; workflow pins agree with seed.lock")
    ret_write_output_stamp(ctx)

pub fn run_test_green_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    if fs.mkdir_all("out/.build-state") != 0:
        return ret_fail(ctx, "could not create out/.build-state")
    let asset = ret_seed_asset_arg(ctx)
    let driver_sha = ret_require_pinned_driver(ctx, asset)
    if driver_sha.len() == 0:
        return 1
    let compiler_path = ret_release_compiler_path()
    if not fs.exists(compiler_path):
        return ret_fail(ctx, "missing " ++ compiler_path)
    let compiler_sha = ret_sha256_file(ctx, "test-green-compiler", compiler_path)
    if compiler_sha.len() == 0:
        return ret_fail(ctx, "could not hash " ++ compiler_path)
    let fingerprint = ret_test_green_fingerprint(ctx)
    if fingerprint.len() == 0:
        return 1
    let commit = ret_git_commit(ctx)
    let commit_label = if commit.len() > 0: commit else: "unknown"
    let manifest =
        "{\n" ++
        "  \"git_commit\": \"" ++ ret_json_escape(commit_label) ++ "\",\n" ++
        "  \"host\": \"" ++ ret_json_escape(os() ++ "/" ++ arch()) ++ "\",\n" ++
        "  \"compiler_sha256\": \"" ++ ret_json_escape(compiler_sha) ++ "\",\n" ++
        "  \"driver_sha256\": \"" ++ ret_json_escape(driver_sha) ++ "\",\n" ++
        "  \"seed_lock_version\": \"" ++ ret_json_escape(seed_lock_version_for(seed_lock_read(fs), asset)) ++ "\",\n" ++
        "  \"test_inputs_fingerprint\": \"" ++ ret_json_escape(fingerprint) ++ "\"\n" ++
        "}\n"
    if fs.write_text("out/.build-state/test-green.json", manifest) != 0:
        return ret_fail(ctx, "could not write out/.build-state/test-green.json")
    print("[test-green] recorded current test evidence in out/.build-state/test-green.json")
    0

fn ret_require_test_green(ctx: &ActionCtx, compiler_sha: &str, driver_sha: &str) -> i32:
    let manifest = if ctx.fs().exists("out/.build-state/test-green.json"): ctx.fs().read_text("out/.build-state/test-green.json") else: ""
    if manifest.len() == 0:
        return ret_fail(ctx, "missing test-green manifest; run `with build :test`")
    let fingerprint = ret_test_green_fingerprint(ctx)
    if fingerprint.len() == 0:
        return 1
    let expected_compiler = "\"compiler_sha256\": \"" ++ compiler_sha ++ "\""
    if not manifest.contains(expected_compiler):
        return ret_fail(ctx, "test-green manifest was recorded for a different compiler; run `with build :test`")
    let expected_driver = "\"driver_sha256\": \"" ++ driver_sha ++ "\""
    if not manifest.contains(expected_driver):
        return ret_fail(ctx, "test-green manifest was not recorded under the pinned seed; run `WITH=$PWD/src/main src/main build :test`")
    let expected_fingerprint = "\"test_inputs_fingerprint\": \"" ++ fingerprint ++ "\""
    if not manifest.contains(expected_fingerprint):
        return ret_fail(ctx, "test-green manifest is stale; run `with build :test`")
    0

/// `fixpoint-compare`: the unit digests of stage1's compile of the compiler
/// (inputs[0]) equal those of stage2's (inputs[1]). A difference names every
/// unit that differs: nondeterminism, or a miscompile by one generation.
pub fn run_fixpoint_compare_units_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let inputs = ctx.inputs()
    if inputs.len() < 2: return ret_fail(ctx, "requires the two unit-digest files")
    let left = fs.read_text(inputs.get(0))
    let right = fs.read_text(inputs.get(1))
    if left.len() == 0: return ret_fail(ctx, "no unit digests in " ++ inputs.get(0) ++ "; the stage2 build records them")
    if right.len() == 0: return ret_fail(ctx, "no unit digests in " ++ inputs.get(1) ++ "; the release build records them")
    let left_lines = left.split("\n")
    let right_lines = right.split("\n")
    var units = 0
    var differing = ""
    let count = if left_lines.len() > right_lines.len(): left_lines.len() else: right_lines.len()
    for i in 0..count as i32:
        let a = if i < left_lines.len() as i32: left_lines.get(i).clone() else: ""
        let b = if i < right_lines.len() as i32: right_lines.get(i).clone() else: ""
        if a.len() == 0 and b.len() == 0: continue
        units = units + 1
        if a != b: differing = differing ++ "\n  stage2: " ++ (if a.len() > 0: a else: "(no such unit)") ++ "\n  stage3: " ++ (if b.len() > 0: b else: "(no such unit)")
    if differing.len() > 0:
        return ret_fail(ctx, "FIXPOINT FAILED: stage2 and stage3 disagree on these units of the compiler" ++ differing ++ "\nrun `with build :fixpoint-diff` for the root module, or rebuild with WITH_KEEP_UNIT_OBJECTS=1 to keep the unit objects")
    print(f"[fixpoint] stage2 == stage3 over all {units} units of the compiler")
    ret_write_output_stamp(ctx)

// D19: evidence is written once by the step that produces it and only read
// thereafter. The fixpoint tier records what it verified — the fixpoint
// object shas, bound to the exact release binary present at verification —
// so the bless step never re-hashes or (worse) rebuilds fixpoint objects to
// re-derive facts the fixpoint run already proved.
pub fn run_fixpoint_evidence_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    if fs.mkdir_all("out/.build-state") != 0:
        return ret_fail(ctx, "could not create out/.build-state")
    let compiler_path = ret_release_compiler_path()
    if not fs.exists(compiler_path):
        return ret_fail(ctx, "missing " ++ compiler_path ++ "; run `with build` first")
    let compiler_sha = ret_sha256_file(ctx, "fixpoint-evidence-compiler", compiler_path)
    if compiler_sha.len() == 0:
        return ret_fail(ctx, "could not hash " ++ compiler_path)
    let stage2_sha = ret_sha256_file(ctx, "fixpoint-evidence-stage2", "out/stage/bin/with-stage2.units")
    let stage3_sha = ret_sha256_file(ctx, "fixpoint-evidence-stage3", "out/release/bin/with.units")
    if stage2_sha.len() == 0 or stage3_sha.len() == 0:
        return ret_fail(ctx, "could not hash fixpoint objects")
    let evidence =
        "{\n" ++
        "  \"compiler_sha256\": \"" ++ ret_json_escape(compiler_sha) ++ "\",\n" ++
        "  \"stage2_fixpoint_sha256\": \"" ++ ret_json_escape(stage2_sha) ++ "\",\n" ++
        "  \"stage3_fixpoint_sha256\": \"" ++ ret_json_escape(stage3_sha) ++ "\"\n" ++
        "}\n"
    if fs.write_text("out/.build-state/fixpoint-evidence.json", evidence) != 0:
        return ret_fail(ctx, "could not write out/.build-state/fixpoint-evidence.json")
    0

// Extract a "key": "value" string field from a manifest written by our own
// evidence writers (flat, escaped values never contain a quote).
fn ret_json_field(manifest: &str, key: &str) -> str:
    let marker = "\"" ++ key ++ "\": \""
    let at = manifest.find(marker)
    if at < 0:
        return ""
    let start = at + marker.len()
    var end = start
    while end < manifest.len() and manifest[end] != 34:
        end = end + 1
    if end >= manifest.len():
        return ""
    manifest.slice(start, end)

pub fn run_last_green_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    if fs.mkdir_all("out/.build-state") != 0:
        return ret_fail(ctx, "could not create out/.build-state")
    let asset = ret_seed_asset_arg(ctx)
    let driver_sha = ret_require_pinned_driver(ctx, asset)
    if driver_sha.len() == 0:
        return 1
    let compiler_path = ret_release_compiler_path()
    if not fs.exists(compiler_path):
        return ret_fail(ctx, "missing " ++ compiler_path)
    let source_version = ret_first_line(fs.read_text("src/version"))
    let compiler_version = ret_compiler_version(ctx, compiler_path)
    if compiler_version.len() == 0:
        return ret_fail(ctx, "could not read verified compiler version")
    let compiler_sha = ret_sha256_file(ctx, "verified-compiler", compiler_path)
    if compiler_sha.len() == 0:
        return ret_fail(ctx, "could not hash " ++ compiler_path)
    if ret_require_test_green(ctx, compiler_sha, driver_sha) != 0:
        return 1
    // D19: read the fixpoint tier's recorded evidence; never re-hash (or
    // rebuild) the objects here. Stale evidence fails loudly instead.
    let fixpoint_evidence = if fs.exists("out/.build-state/fixpoint-evidence.json"): fs.read_text("out/.build-state/fixpoint-evidence.json") else: ""
    if fixpoint_evidence.len() == 0:
        return ret_fail(ctx, "missing fixpoint evidence; run `with build :fixpoint`")
    if ret_json_field(fixpoint_evidence, "compiler_sha256") != compiler_sha:
        return ret_fail(ctx, "fixpoint evidence was recorded for a different compiler; run `with build :fixpoint`")
    let stage2_sha = ret_json_field(fixpoint_evidence, "stage2_fixpoint_sha256")
    let stage3_sha = ret_json_field(fixpoint_evidence, "stage3_fixpoint_sha256")
    if stage2_sha.len() == 0 or stage3_sha.len() == 0:
        return ret_fail(ctx, "fixpoint evidence is malformed; run `with build :fixpoint`")
    let commit = ret_git_commit(ctx)
    let commit_label = if commit.len() > 0: commit else: "unknown"
    if ret_archive_verified_seed(ctx, source_version, commit_label, compiler_sha) != 0:
        return 1
    let seed_input = if fs.exists("out/.build-state/seed-input.json"): fs.read_text("out/.build-state/seed-input.json") else: ""
    // The stage chain was seeded by the pinned seed too, not merely driven
    // by it (stage1 records the compiler it was built with).
    if ret_json_field(seed_input, "sha256") != driver_sha:
        return ret_fail(ctx, ret_pinned_driver_fix("stage1 was seeded by " ++ ret_json_field(seed_input, "resolved_path") ++ " (sha256 " ++ ret_json_field(seed_input, "sha256") ++ "), not the pinned seed"))
    let seed_json = if seed_input.len() > 0: ret_trim(seed_input) else: "null"
    let identity = ret_source_identity(ctx, driver_sha)
    // The store as it will be published (last-green-publish installs this
    // file): what is there now, plus this green when the tree has an identity.
    var store = fs.host_read_text(ret_green_store_path())
    if identity.len() > 0 and ret_green_store_line(store, identity).len() == 0:
        if store.len() > 0 and not store.ends_with("\n"): store = store ++ "\n"
        store = store ++ identity ++ "\t" ++ commit_label ++ "\t" ++ compiler_version ++ "\t" ++ driver_sha ++ "\n"
    if fs.write_text("out/.build-state/green-store.tsv", store) != 0:
        return ret_fail(ctx, "could not write out/.build-state/green-store.tsv")
    if identity.len() == 0:
        print("[last-green] the worktree is not clean: this green is local to it and is not published")
    let manifest =
        "{\n" ++
        "  \"source_version\": \"" ++ ret_json_escape(source_version) ++ "\",\n" ++
        "  \"source_identity\": \"" ++ ret_json_escape(identity) ++ "\",\n" ++
        "  \"compiler_version\": \"" ++ ret_json_escape(compiler_version) ++ "\",\n" ++
        "  \"git_commit\": \"" ++ ret_json_escape(commit_label) ++ "\",\n" ++
        "  \"host\": \"" ++ ret_json_escape(os() ++ "/" ++ arch()) ++ "\",\n" ++
        "  \"compiler_sha256\": \"" ++ ret_json_escape(compiler_sha) ++ "\",\n" ++
        "  \"driver_sha256\": \"" ++ ret_json_escape(driver_sha) ++ "\",\n" ++
        "  \"stage2_fixpoint_sha256\": \"" ++ ret_json_escape(stage2_sha) ++ "\",\n" ++
        "  \"stage3_fixpoint_sha256\": \"" ++ ret_json_escape(stage3_sha) ++ "\",\n" ++
        "  \"seed_retention_count\": " ++ f"{RET_SEED_KEEP}" ++ ",\n" ++
        "  \"seed_input\": " ++ seed_json ++ "\n" ++
        "}\n"
    if fs.write_text("out/.build-state/last-green.json", manifest) != 0:
        return ret_fail(ctx, "could not write out/.build-state/last-green.json")
    print("[last-green] archived verified seed and wrote out/.build-state/last-green.json")
    0

/// Whether this clean tree, built by the pinned seed, has a published green:
/// the release compiler here was built from sources a battery already passed.
fn ret_green_by_identity(ctx: &ActionCtx) -> bool:
    let fs = ctx.fs()
    let seed_input = if fs.exists("out/.build-state/seed-input.json"): fs.read_text("out/.build-state/seed-input.json") else: ""
    let seeded_by = ret_json_field(seed_input, "sha256")
    // the chain here was seeded by a compiler seed.lock pins
    if seeded_by.len() != 64 or not seed_lock_read(fs).contains(seeded_by): return false
    let identity = ret_source_identity(ctx, seeded_by)
    let line = ret_green_store_line(fs.host_read_text(ret_green_store_path()), identity)
    if line.len() == 0: return false
    let fields = line.split("\t")
    let commit = if fields.len() > 1: fields.get(1).clone() else: ""
    print("[" ++ ctx.target_name() ++ "] these sources are green: recorded at commit " ++ commit ++ " (" ++ ret_green_store_path() ++ ")")
    true

pub fn run_require_last_green_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let compiler_path = ret_release_compiler_path()
    if not fs.exists(compiler_path):
        return ret_fail(ctx, "missing " ++ compiler_path ++ "; run `with build` first")
    let manifest = if fs.exists("out/.build-state/last-green.json"): fs.read_text("out/.build-state/last-green.json") else: ""
    if manifest.len() == 0 and ret_green_by_identity(ctx):
        return ret_write_output_stamp(ctx)
    if manifest.len() == 0:
        return ret_fail(ctx, "missing last-green manifest; run `with build :last-green` after build/fixpoint/test")
    let compiler_sha = ret_sha256_file(ctx, "verified-compiler-check", compiler_path)
    if compiler_sha.len() == 0:
        return ret_fail(ctx, "could not hash " ++ compiler_path)
    let expected = "\"compiler_sha256\": \"" ++ compiler_sha ++ "\""
    if not manifest.contains(expected) and ret_green_by_identity(ctx):
        return ret_write_output_stamp(ctx)
    if not manifest.contains(expected):
        return ret_fail(ctx, compiler_path ++ " is not the compiler recorded by last-green; run `with build`, `with build :fixpoint`, `with build :test`, then `with build :last-green`")
    let output = ctx.output()
    if output.len() > 0:
        let dir = ret_dirname(output)
        if dir.len() > 0 and fs.mkdir_all(dir) != 0:
            return ret_fail(ctx, "could not create " ++ dir)
        if fs.write_text(output, "ok\n") != 0:
            return ret_fail(ctx, "could not write " ++ output)
    0

fn ret_live_targets(args: &Vec[str]) -> Vec[str]:
    let live: Vec[str] = Vec.new()
    let prefix = "live-target="
    for i in 0..args.len() as i32:
        let arg = args[i]
        if arg.starts_with(prefix):
            live.push(arg.slice(prefix.len(), arg.len()))
    live

fn ret_state_target_name(path: &str) -> str:
    if not path.starts_with("out/.build-state/") or not path.ends_with(".state"):
        return ""
    let base = ret_basename(path)
    base.slice(0, base.len() - 6)

fn ret_add_stale_state_files(fs: &ToolFs, live_targets: Vec[str], candidates: Vec[str]) -> Vec[str]:
    var out = candidates
    if live_targets.len() == 0 or not fs.exists("out/.build-state"):
        return out
    let files = fs.list_files("out/.build-state")
    for i in 0..files.len() as i32:
        let path = files[i]
        let target_name = ret_state_target_name(path)
        if target_name.len() > 0 and not ret_vec_contains(live_targets, target_name):
            out = ret_add_unique(out, path)
    out

fn ret_add_old_seed_archives(fs: &ToolFs, candidates: Vec[str]) -> Vec[str]:
    var out = candidates
    let entries = ret_seed_manifest_entries(fs)
    var keep_from = entries.len() as i32 - RET_SEED_KEEP
    if keep_from <= 0:
        return out
    for i in 0..keep_from:
        let path = entries[i]
        if fs.exists(path):
            out = ret_add_unique(out, path)
    out

fn ret_release_artifact_version(path: &str) -> str:
    if ret_dirname(path) != "out/release":
        return ""
    let base = ret_basename(path)
    let notes_prefix = "notes-"
    let notes_suffix = ".md"
    if base.starts_with(notes_prefix) and base.ends_with(notes_suffix):
        let version = base.slice(notes_prefix.len(), base.len() - notes_suffix.len())
        if version.starts_with("v"):
            return version
    let bootstrap_prefix = "with-bootstrap-c-"
    let bootstrap_suffix = ".tar.zst"
    if base.starts_with(bootstrap_prefix) and base.ends_with(bootstrap_suffix):
        let version = base.slice(bootstrap_prefix.len(), base.len() - bootstrap_suffix.len())
        if version.starts_with("v"):
            return version
    ""

fn ret_release_artifact_versions(fs: &ToolFs) -> Vec[str]:
    var versions: Vec[str] = Vec.new()
    if not fs.exists("out/release"):
        return versions
    let files = fs.list_files("out/release")
    for i in 0..files.len() as i32:
        let version = ret_release_artifact_version(files[i])
        versions = ret_add_unique(versions, version)
    ret_sorted_release_versions(versions)

fn ret_stale_release_artifact_versions(fs: &ToolFs) -> Vec[str]:
    let versions = ret_release_artifact_versions(fs)
    let stale: Vec[str] = Vec.new()
    let stale_count = versions.len() as i32 - RET_RELEASE_VERSION_KEEP
    if stale_count <= 0:
        return stale
    for i in 0..stale_count:
        stale.push(retention_owned_text(versions[i]))
    stale

fn ret_add_old_release_artifacts(fs: &ToolFs, candidates: Vec[str]) -> Vec[str]:
    var out = candidates
    let stale_versions = ret_stale_release_artifact_versions(fs)
    if stale_versions.len() == 0 or not fs.exists("out/release"):
        return out
    let files = fs.list_files("out/release")
    for i in 0..files.len() as i32:
        let path = files[i]
        let version = ret_release_artifact_version(path)
        if ret_vec_contains(stale_versions, version):
            out = ret_add_unique(out, path)
    out

fn ret_small_prune_candidates(ctx: &ActionCtx) -> Vec[str]:
    let fs = ctx.fs()
    var candidates: Vec[str] = Vec.new()
    candidates = ret_add_stale_state_files(fs, ret_live_targets(ctx.args()), move candidates)
    candidates = ret_add_old_seed_archives(fs, move candidates)
    candidates = ret_add_old_release_artifacts(fs, move candidates)
    ret_sorted_strings(candidates)

fn ret_apply_small_prune(ctx: &ActionCtx, candidates: Vec[str]) -> i32:
    let fs = ctx.fs()
    var removed = 0
    for i in 0..candidates.len() as i32:
        let path = candidates[i]
        var rc = 0
        if fs.is_dir(path):
            rc = fs.remove_tree(path)
        else:
            rc = fs.remove_file(path)
        if rc == 0:
            removed = removed + 1
    print(f"[prune] removed {removed} stale retained artifact(s)")
    0

fn ret_immediate_children(fs: &ToolFs, dir: &str) -> Vec[str]:
    let out: Vec[str] = Vec.new()
    if not fs.exists(dir):
        return out
    let files = fs.list_files(dir)
    for i in 0..files.len() as i32:
        let path = files[i]
        if ret_dirname(path) == dir:
            out.push(retention_owned_text(path))
    ret_sorted_strings(out)

fn ret_temp_bin_candidates(fs: &ToolFs) -> Vec[str]:
    let out: Vec[str] = Vec.new()
    let files = ret_immediate_children(fs, "out/bin")
    for i in 0..files.len() as i32:
        let path = files[i]
        let base = ret_basename(path)
        if fs.is_dir(path):
            if base.contains(".tmp.") and base.ends_with(".dSYM"):
                out.push(retention_owned_text(path))
        else if base.contains(".tmp."):
            out.push(retention_owned_text(path))
    ret_sorted_strings(out)

fn ret_temp_archive_candidates(fs: &ToolFs, dir: &str) -> Vec[str]:
    let out: Vec[str] = Vec.new()
    let files = ret_immediate_children(fs, dir)
    for i in 0..files.len() as i32:
        let path = files[i]
        let base = ret_basename(path)
        if not fs.is_dir(path) and base.contains(".o.") and base.ends_with(".a"):
            out.push(retention_owned_text(path))
    ret_sorted_strings(out)

fn ret_issue61_stale_candidates(fs: &ToolFs) -> Vec[str]:
    let out: Vec[str] = Vec.new()
    let files = ret_immediate_children(fs, "out/test-graph/issue61-regression")
    for i in 0..files.len() as i32:
        let path = files[i]
        if fs.is_dir(path) and ret_basename(path) != "repo":
            out.push(retention_owned_text(path))
    ret_sorted_strings(out)

fn ret_embedded_compiler_candidates(fs: &ToolFs) -> Vec[str]:
    let out: Vec[str] = Vec.new()
    let path = "out/test-graph/embedded-runtime-regression/with"
    if fs.exists(path) and not fs.is_dir(path):
        out.push(path)
    out

fn ret_remove_prune_candidates(ctx: &ActionCtx, candidates: &Vec[str]) -> i32:
    let fs = ctx.fs()
    for i in 0..candidates.len() as i32:
        let path = candidates[i]
        let rc = if fs.is_dir(path): fs.remove_tree(path) else: fs.remove_file(path)
        if rc != 0:
            return ret_fail(ctx, "could not remove stale artifact: " ++ path)
    0

fn ret_append_all_prune_candidates(out: Vec[str], candidates: &Vec[str]) -> Vec[str]:
    var combined = out
    for i in 0..candidates.len() as i32:
        combined = ret_add_unique(combined, candidates[i])
    combined

fn ret_apply_large_prune(ctx: &ActionCtx) -> i32:
    let fs = ctx.fs()
    let bin = ret_temp_bin_candidates(fs)
    let lib = ret_temp_archive_candidates(fs, "out/lib")
    let bootstrap = ret_temp_archive_candidates(fs, "out/bootstrap-lib")
    let issue61 = ret_issue61_stale_candidates(fs)
    let embedded = ret_embedded_compiler_candidates(fs)
    var all: Vec[str] = Vec.new()
    all = ret_append_all_prune_candidates(move all, bin)
    all = ret_append_all_prune_candidates(move all, lib)
    all = ret_append_all_prune_candidates(move all, bootstrap)
    all = ret_append_all_prune_candidates(move all, issue61)
    all = ret_append_all_prune_candidates(move all, embedded)
    if ret_remove_prune_candidates(ctx, all) != 0:
        return 1
    print(f"[prune] removed temp out/bin entries: {bin.len()}")
    print(f"[prune] removed temp out/lib archives: {lib.len()}")
    print(f"[prune] removed temp out/bootstrap-lib archives: {bootstrap.len()}")
    print(f"[prune] removed stale issue61 regression directories: {issue61.len()}")
    print(f"[prune] removed retained embedded runtime compiler copies: {embedded.len()}")
    0

fn ret_report_prune(candidates: Vec[str]):
    print(f"[prune] {candidates.len()} stale state/seed/release artifact(s) would be removed")
    var shown = 0
    for i in 0..candidates.len() as i32:
        if shown >= 50:
            break
        print("  " ++ candidates[i])
        shown = shown + 1
    if candidates.len() as i32 > shown:
        print(f"  ... and {candidates.len() as i32 - shown} more")

fn ret_report_large_prune(ctx: &ActionCtx):
    let fs = ctx.fs()
    let bin = ret_temp_bin_candidates(fs)
    let lib = ret_temp_archive_candidates(fs, "out/lib")
    let bootstrap = ret_temp_archive_candidates(fs, "out/bootstrap-lib")
    let issue61 = ret_issue61_stale_candidates(fs)
    let embedded = ret_embedded_compiler_candidates(fs)
    print(f"[prune] temp out/bin entries: {bin.len()}")
    print(f"[prune] temp out/lib archives: {lib.len()}")
    print(f"[prune] temp out/bootstrap-lib archives: {bootstrap.len()}")
    print(f"[prune] stale issue61 regression directories: {issue61.len()}")
    print(f"[prune] retained embedded runtime compiler copies: {embedded.len()}")
    var examples: Vec[str] = Vec.new()
    examples = ret_append_all_prune_candidates(move examples, bin)
    examples = ret_append_all_prune_candidates(move examples, lib)
    examples = ret_append_all_prune_candidates(move examples, bootstrap)
    examples = ret_append_all_prune_candidates(move examples, issue61)
    examples = ret_append_all_prune_candidates(move examples, embedded)
    examples = ret_sorted_strings(examples)
    var shown = 0
    for i in 0..examples.len() as i32:
        if shown >= 50:
            break
        print("  " ++ examples[i])
        shown = shown + 1

pub fn run_prune_action(ctx: ActionCtx) -> i32:
    let mode = if ctx.args().len() > 0: retention_owned_text(ctx.args().get(0)) else: "dry-run"
    if mode == "apply":
        if ret_apply_large_prune(ctx) != 0:
            return 1
        if ret_apply_small_prune(ctx, ret_small_prune_candidates(ctx)) != 0:
            return 1
        return ret_write_output_stamp(ctx)
    ret_report_large_prune(ctx)
    ret_report_prune(ret_small_prune_candidates(ctx))
    ret_write_output_stamp(ctx)
