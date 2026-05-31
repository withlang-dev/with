module build.retention

use std.build
use std.sysinfo

const RET_SEED_KEEP: i32 = 5

fn ret_fail(ctx: ActionCtx, message: str) -> i32:
    ctx.diagnostics().error(ctx.target_name() ++ ": " ++ message)
    1

fn ret_write_output_stamp(ctx: ActionCtx) -> i32:
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

fn ret_join(left: str, right: str) -> str:
    if left.len() == 0:
        return right
    if right.len() == 0:
        return left
    if left.ends_with("/"):
        return left ++ right
    left ++ "/" ++ right

fn ret_abs(root: str, path: str) -> str:
    if path.len() > 0 and path.byte_at(0) == 47:
        return path
    ret_join(root, path)

fn ret_dirname(path: str) -> str:
    var last_slash = -1
    for i in 0..path.len() as i32:
        if path.byte_at(i as i64) == 47:
            last_slash = i
    if last_slash < 0:
        return "."
    if last_slash == 0:
        return "/"
    path.slice(0, last_slash as i64)

fn ret_basename(path: str) -> str:
    var last_slash = -1
    for i in 0..path.len() as i32:
        if path.byte_at(i as i64) == 47:
            last_slash = i
    if last_slash < 0:
        return path
    path.slice((last_slash + 1) as i64, path.len())

fn ret_trim(text: str) -> str:
    var start = 0
    var end = text.len() as i32
    while start < end:
        let ch = text.byte_at(start as i64)
        if ch != 9 and ch != 10 and ch != 13 and ch != 32:
            break
        start = start + 1
    while end > start:
        let ch = text.byte_at((end - 1) as i64)
        if ch != 9 and ch != 10 and ch != 13 and ch != 32:
            break
        end = end - 1
    text.slice(start as i64, end as i64)

fn ret_first_line(text: str) -> str:
    var end = text.len() as i32
    for i in 0..text.len() as i32:
        let ch = text.byte_at(i as i64)
        if ch == 10 or ch == 13:
            end = i
            break
    ret_trim(text.slice(0, end as i64))

fn ret_first_field(text: str) -> str:
    let line = ret_first_line(text)
    for i in 0..line.len() as i32:
        let ch = line.byte_at(i as i64)
        if ch == 9 or ch == 32:
            return line.slice(0, i as i64)
    line

fn ret_split_lines(text: str) -> Vec[str]:
    let out: Vec[str] = Vec.new()
    var start = 0
    for i in 0..text.len() as i32:
        let ch = text.byte_at(i as i64)
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

fn ret_json_escape(text: str) -> str:
    var out = ""
    for i in 0..text.len() as i32:
        let ch = text.byte_at(i as i64)
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

fn ret_safe_label(text: str) -> str:
    var out = ""
    for i in 0..text.len() as i32:
        let ch = text.byte_at(i as i64)
        let keep = (ch >= 48 and ch <= 57) or (ch >= 65 and ch <= 90) or (ch >= 97 and ch <= 122) or ch == 45 or ch == 46 or ch == 95
        if keep:
            out = out ++ text.slice(i as i64, (i + 1) as i64)
        else:
            out = out ++ "_"
    if out.len() == 0:
        return "unknown"
    out

fn ret_short(text: str, n: i32) -> str:
    if text.len() <= n:
        return text
    text.slice(0, n as i64)

fn ret_run_first_line(ctx: ActionCtx, label: str, args: Vec[str], timeout_ms: i32) -> str:
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

fn ret_run_lines(ctx: ActionCtx, label: str, args: Vec[str], timeout_ms: i32) -> Vec[str]:
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

fn ret_run_status(ctx: ActionCtx, label: str, args: Vec[str], timeout_ms: i32) -> i32:
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

fn ret_shell_first_line(ctx: ActionCtx, label: str, script: str) -> str:
    let args: Vec[str] = Vec.new()
    args.push("sh")
    args.push("-c")
    args.push(script)
    ret_run_first_line(ctx, label, args, 120000)

fn ret_shell_lines(ctx: ActionCtx, label: str, script: str) -> Vec[str]:
    let args: Vec[str] = Vec.new()
    args.push("sh")
    args.push("-c")
    args.push(script)
    ret_run_lines(ctx, label, args, 120000)

fn ret_sha256_file(ctx: ActionCtx, label: str, path: str) -> str:
    let root = ctx.project_info().project_root()
    let target_path = ret_abs(root, path)
    let shasum_args: Vec[str] = Vec.new()
    shasum_args.push("shasum")
    shasum_args.push("-a")
    shasum_args.push("256")
    shasum_args.push(target_path)
    let shasum = ret_run_first_line(ctx, label ++ "-shasum", shasum_args, 30000)
    if shasum.len() > 0:
        return ret_first_field(shasum)
    let sha256_args: Vec[str] = Vec.new()
    sha256_args.push("sha256sum")
    sha256_args.push(target_path)
    let sha256 = ret_run_first_line(ctx, label ++ "-sha256sum", sha256_args, 30000)
    if sha256.len() > 0:
        return ret_first_field(sha256)
    ""

fn ret_git_commit(ctx: ActionCtx) -> str:
    let args: Vec[str] = Vec.new()
    args.push("git")
    args.push("rev-parse")
    args.push("HEAD")
    ret_run_first_line(ctx, "git-head", args, 30000)

fn ret_compiler_version(ctx: ActionCtx, compiler_path: str) -> str:
    let root = ctx.project_info().project_root()
    let args: Vec[str] = Vec.new()
    args.push(ret_abs(root, compiler_path))
    args.push("version")
    ret_run_first_line(ctx, "compiler-version", args, 60000)

fn ret_vec_contains(items: Vec[str], item: str) -> bool:
    for i in 0..items.len() as i32:
        if items.get(i as i64) == item:
            return true
    false

fn ret_add_unique(items: Vec[str], item: str):
    if item.len() == 0:
        return
    if not ret_vec_contains(items, item):
        items.push(item)

fn ret_manifest_lines_without(manifest: Vec[str], skip: str) -> Vec[str]:
    let out: Vec[str] = Vec.new()
    for i in 0..manifest.len() as i32:
        let item = manifest.get(i as i64)
        if item != skip:
            out.push(item)
    out

fn ret_join_lines(items: Vec[str]) -> str:
    var out = ""
    for i in 0..items.len() as i32:
        out = out ++ items.get(i as i64) ++ "\n"
    out

fn ret_seed_manifest_entries(fs: ToolFs) -> Vec[str]:
    if not fs.exists("out/seed-archive/manifest.tsv"):
        return Vec.new()
    ret_split_lines(fs.read_text("out/seed-archive/manifest.tsv"))

fn ret_archive_verified_seed(ctx: ActionCtx, version: str, commit: str, sha256: str) -> i32:
    let fs = ctx.fs()
    if fs.mkdir_all("out/seed-archive") != 0:
        return ret_fail(ctx, "could not create out/seed-archive")
    let archive = "out/seed-archive/with-" ++ ret_safe_label(version) ++ "-" ++ ret_short(commit, 12) ++ "-" ++ ret_short(sha256, 12)
    if not fs.exists(archive):
        if fs.copy_file("out/bin/with", archive) != 0:
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
            trimmed.push(entries.get(i as i64))
        entries = trimmed
    if fs.write_text("out/seed-archive/manifest.tsv", ret_join_lines(entries)) != 0:
        return ret_fail(ctx, "could not write out/seed-archive/manifest.tsv")
    0

pub fn run_last_green_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    if fs.mkdir_all("out/.build-state") != 0:
        return ret_fail(ctx, "could not create out/.build-state")
    if not fs.exists("out/bin/with"):
        return ret_fail(ctx, "missing out/bin/with")
    let source_version = ret_first_line(fs.read_text("src/version"))
    let compiler_version = ret_compiler_version(ctx, "out/bin/with")
    if compiler_version.len() == 0:
        return ret_fail(ctx, "could not read verified compiler version")
    let compiler_sha = ret_sha256_file(ctx, "verified-compiler", "out/bin/with")
    if compiler_sha.len() == 0:
        return ret_fail(ctx, "could not hash out/bin/with")
    let stage2_sha = ret_sha256_file(ctx, "stage2-fixpoint", "out/bin/with-stage2-fixpoint.o")
    let stage3_sha = ret_sha256_file(ctx, "stage3-fixpoint", "out/bin/with-stage3-fixpoint.o")
    let commit = ret_git_commit(ctx)
    let commit_label = if commit.len() > 0: commit else: "unknown"
    if ret_archive_verified_seed(ctx, source_version, commit_label, compiler_sha) != 0:
        return 1
    let seed_input = fs.read_text("out/.build-state/seed-input.json")
    let seed_json = if seed_input.len() > 0: ret_trim(seed_input) else: "null"
    let manifest =
        "{\n" ++
        "  \"source_version\": \"" ++ ret_json_escape(source_version) ++ "\",\n" ++
        "  \"compiler_version\": \"" ++ ret_json_escape(compiler_version) ++ "\",\n" ++
        "  \"git_commit\": \"" ++ ret_json_escape(commit_label) ++ "\",\n" ++
        "  \"host\": \"" ++ ret_json_escape(os() ++ "/" ++ arch()) ++ "\",\n" ++
        "  \"compiler_sha256\": \"" ++ ret_json_escape(compiler_sha) ++ "\",\n" ++
        "  \"stage2_fixpoint_sha256\": \"" ++ ret_json_escape(stage2_sha) ++ "\",\n" ++
        "  \"stage3_fixpoint_sha256\": \"" ++ ret_json_escape(stage3_sha) ++ "\",\n" ++
        "  \"seed_retention_count\": " ++ f"{RET_SEED_KEEP}" ++ ",\n" ++
        "  \"seed_input\": " ++ seed_json ++ "\n" ++
        "}\n"
    if fs.write_text("out/.build-state/last-green.json", manifest) != 0:
        return ret_fail(ctx, "could not write out/.build-state/last-green.json")
    print("[last-green] archived verified seed and wrote out/.build-state/last-green.json")
    0

fn ret_live_targets(args: Vec[str]) -> Vec[str]:
    let live: Vec[str] = Vec.new()
    let prefix = "live-target="
    for i in 0..args.len() as i32:
        let arg = args.get(i as i64)
        if arg.starts_with(prefix):
            live.push(arg.slice(prefix.len(), arg.len()))
    live

fn ret_state_target_name(path: str) -> str:
    if not path.starts_with("out/.build-state/") or not path.ends_with(".state"):
        return ""
    let base = ret_basename(path)
    base.slice(0, base.len() - 6)

fn ret_add_stale_state_files(fs: ToolFs, live_targets: Vec[str], candidates: Vec[str]):
    if live_targets.len() == 0 or not fs.exists("out/.build-state"):
        return
    let files = fs.list_files("out/.build-state")
    for i in 0..files.len() as i32:
        let path = files.get(i as i64)
        let target_name = ret_state_target_name(path)
        if target_name.len() > 0 and not ret_vec_contains(live_targets, target_name):
            ret_add_unique(candidates, path)

fn ret_add_old_seed_archives(fs: ToolFs, candidates: Vec[str]):
    let entries = ret_seed_manifest_entries(fs)
    var keep_from = entries.len() as i32 - RET_SEED_KEEP
    if keep_from <= 0:
        return
    for i in 0..keep_from:
        let path = entries.get(i as i64)
        if fs.exists(path):
            ret_add_unique(candidates, path)

fn ret_small_prune_candidates(ctx: ActionCtx) -> Vec[str]:
    let fs = ctx.fs()
    let candidates: Vec[str] = Vec.new()
    ret_add_stale_state_files(fs, ret_live_targets(ctx.args()), candidates)
    ret_add_old_seed_archives(fs, candidates)
    candidates

fn ret_apply_small_prune(ctx: ActionCtx, candidates: Vec[str]) -> i32:
    let fs = ctx.fs()
    var removed = 0
    for i in 0..candidates.len() as i32:
        let path = candidates.get(i as i64)
        var rc = 0
        if fs.is_dir(path):
            rc = fs.remove_tree(path)
        else:
            rc = fs.remove_file(path)
        if rc == 0:
            removed = removed + 1
    print(f"[prune] removed {removed} stale build artifact(s)")
    0

fn ret_apply_large_prune(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let bin_count = ret_shell_first_line(ctx, "apply-count-temp-bin", "if [ -d out/bin ]; then find out/bin -maxdepth 1 \\( -type d -name '*.tmp.*.dSYM' -o -type f -name '*.tmp.*' \\) -print | wc -l; else echo 0; fi")
    let lib_count = ret_shell_first_line(ctx, "apply-count-temp-lib-archives", "if [ -d out/lib ]; then find out/lib -maxdepth 1 -type f -name '*.o.*.a' -print | wc -l; else echo 0; fi")
    let bootstrap_count = ret_shell_first_line(ctx, "apply-count-temp-bootstrap-archives", "if [ -d out/bootstrap-lib ]; then find out/bootstrap-lib -maxdepth 1 -type f -name '*.o.*.a' -print | wc -l; else echo 0; fi")
    if fs.exists("out/bin"):
        let dsym_args: Vec[str] = Vec.new()
        dsym_args.push("find")
        dsym_args.push("out/bin")
        dsym_args.push("-maxdepth")
        dsym_args.push("1")
        dsym_args.push("-type")
        dsym_args.push("d")
        dsym_args.push("-name")
        dsym_args.push("*.tmp.*.dSYM")
        dsym_args.push("-exec")
        dsym_args.push("rm")
        dsym_args.push("-rf")
        dsym_args.push("{}")
        dsym_args.push("+")
        if ret_run_status(ctx, "delete-temp-dsym", dsym_args, 300000) != 0:
            return 1
        let tmp_args: Vec[str] = Vec.new()
        tmp_args.push("find")
        tmp_args.push("out/bin")
        tmp_args.push("-maxdepth")
        tmp_args.push("1")
        tmp_args.push("-type")
        tmp_args.push("f")
        tmp_args.push("-name")
        tmp_args.push("*.tmp.*")
        tmp_args.push("-delete")
        if ret_run_status(ctx, "delete-temp-bin", tmp_args, 300000) != 0:
            return 1
    if fs.exists("out/lib"):
        let lib_args: Vec[str] = Vec.new()
        lib_args.push("find")
        lib_args.push("out/lib")
        lib_args.push("-maxdepth")
        lib_args.push("1")
        lib_args.push("-type")
        lib_args.push("f")
        lib_args.push("-name")
        lib_args.push("*.o.*.a")
        lib_args.push("-delete")
        if ret_run_status(ctx, "delete-temp-lib-archives", lib_args, 300000) != 0:
            return 1
    if fs.exists("out/bootstrap-lib"):
        let bootstrap_args: Vec[str] = Vec.new()
        bootstrap_args.push("find")
        bootstrap_args.push("out/bootstrap-lib")
        bootstrap_args.push("-maxdepth")
        bootstrap_args.push("1")
        bootstrap_args.push("-type")
        bootstrap_args.push("f")
        bootstrap_args.push("-name")
        bootstrap_args.push("*.o.*.a")
        bootstrap_args.push("-delete")
        if ret_run_status(ctx, "delete-temp-bootstrap-archives", bootstrap_args, 300000) != 0:
            return 1
    print("[prune] removed temp out/bin entries: " ++ ret_trim(bin_count))
    print("[prune] removed temp out/lib archives: " ++ ret_trim(lib_count))
    print("[prune] removed temp out/bootstrap-lib archives: " ++ ret_trim(bootstrap_count))
    0

fn ret_report_prune(candidates: Vec[str]):
    print(f"[prune] {candidates.len()} stale state/seed artifact(s) would be removed")
    var shown = 0
    for i in 0..candidates.len() as i32:
        if shown >= 50:
            break
        print("  " ++ candidates.get(i as i64))
        shown = shown + 1
    if candidates.len() as i32 > shown:
        print(f"  ... and {candidates.len() as i32 - shown} more")

fn ret_report_large_prune(ctx: ActionCtx):
    let bin_count = ret_shell_first_line(ctx, "count-temp-bin", "if [ -d out/bin ]; then find out/bin -maxdepth 1 \\( -type d -name '*.tmp.*.dSYM' -o -type f -name '*.tmp.*' \\) -print | wc -l; else echo 0; fi")
    let lib_count = ret_shell_first_line(ctx, "count-temp-lib-archives", "if [ -d out/lib ]; then find out/lib -maxdepth 1 -type f -name '*.o.*.a' -print | wc -l; else echo 0; fi")
    let bootstrap_count = ret_shell_first_line(ctx, "count-temp-bootstrap-archives", "if [ -d out/bootstrap-lib ]; then find out/bootstrap-lib -maxdepth 1 -type f -name '*.o.*.a' -print | wc -l; else echo 0; fi")
    print("[prune] temp out/bin entries: " ++ ret_trim(bin_count))
    print("[prune] temp out/lib archives: " ++ ret_trim(lib_count))
    print("[prune] temp out/bootstrap-lib archives: " ++ ret_trim(bootstrap_count))
    let examples = ret_shell_lines(ctx, "sample-temp-artifacts", "if [ -d out/bin ]; then find out/bin -maxdepth 1 \\( -type d -name '*.tmp.*.dSYM' -o -type f -name '*.tmp.*' \\) -print; fi; if [ -d out/lib ]; then find out/lib -maxdepth 1 -type f -name '*.o.*.a' -print | sed -n '1,30p'; fi; if [ -d out/bootstrap-lib ]; then find out/bootstrap-lib -maxdepth 1 -type f -name '*.o.*.a' -print | sed -n '1,10p'; fi")
    var shown = 0
    for i in 0..examples.len() as i32:
        if shown >= 50:
            break
        print("  " ++ examples.get(i as i64))
        shown = shown + 1

pub fn run_prune_action(ctx: ActionCtx) -> i32:
    let mode = if ctx.args().len() > 0: ctx.args().get(0) else: "dry-run"
    if mode == "apply":
        if ret_apply_large_prune(ctx) != 0:
            return 1
        if ret_apply_small_prune(ctx, ret_small_prune_candidates(ctx)) != 0:
            return 1
        return ret_write_output_stamp(ctx)
    ret_report_large_prune(ctx)
    ret_report_prune(ret_small_prune_candidates(ctx))
    ret_write_output_stamp(ctx)
