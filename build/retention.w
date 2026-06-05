module build.retention

use std.build
use std.sysinfo
use std.process

const RET_SEED_KEEP: i32 = 5
const RET_RELEASE_VERSION_KEEP: i32 = 5

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

fn ret_sha256_text(ctx: ActionCtx, label: str, text: str) -> str:
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

fn ret_str_compare(a: str, b: str) -> i32:
    let min_len = if a.len() < b.len(): a.len() else: b.len()
    for i in 0..min_len as i32:
        let ac = a.byte_at(i as i64)
        let bc = b.byte_at(i as i64)
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
        let item = items.get(i as i64)
        var inserted = false
        let next: Vec[str] = Vec.new()
        for j in 0..sorted.len() as i32:
            let existing = sorted.get(j as i64)
            if not inserted and ret_str_compare(item, existing) < 0:
                next.push(item)
                inserted = true
            next.push(existing)
        if not inserted:
            next.push(item)
        sorted = next
    sorted

fn ret_release_version_component(version: str, part: i32) -> i32:
    var start = 0
    if version.starts_with("v"):
        start = 1
    var current = 0
    while current < part:
        var dot = -1
        for i in start..version.len() as i32:
            if version.byte_at(i as i64) == 46:
                dot = i
                break
        if dot < 0:
            return -1
        start = dot + 1
        current = current + 1
    var end = version.len() as i32
    for i in start..version.len() as i32:
        if version.byte_at(i as i64) == 46:
            end = i
            break
    if end <= start:
        return -1
    var value = 0
    for i in start..end:
        let ch = version.byte_at(i as i64)
        if ch < 48 or ch > 57:
            return -1
        value = value * 10 + (ch - 48)
    value

fn ret_release_version_compare(a: str, b: str) -> i32:
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
        let item = items.get(i as i64)
        var inserted = false
        let next: Vec[str] = Vec.new()
        for j in 0..sorted.len() as i32:
            let existing = sorted.get(j as i64)
            if not inserted and ret_release_version_compare(item, existing) < 0:
                next.push(item)
                inserted = true
            next.push(existing)
        if not inserted:
            next.push(item)
        sorted = next
    sorted

fn ret_direct_w_files(fs: ToolFs, dir: str) -> Vec[str]:
    let out: Vec[str] = Vec.new()
    let files = fs.list_files(dir)
    for i in 0..files.len() as i32:
        let path = files.get(i as i64)
        if path.ends_with(".w") and ret_dirname(path) == dir:
            out.push(path)
    ret_sorted_strings(out)

fn ret_expected_test_marker(ctx: ActionCtx, target_name: str, entry: str) -> str:
    let fs = ctx.fs()
    let compiler_path = ret_host_bin("out/bin/with")
    var text = "v1\n"
    text = text ++ "target:" ++ target_name ++ "\n"
    text = text ++ "kind:2\n"
    text = text ++ "entry:" ++ entry ++ "\n"
    text = text ++ "output:\n"
    text = text ++ "opt:0\n"
    text = text ++ "target-kind:0\n"
    text = text ++ "arg:compiler=" ++ compiler_path ++ "\n"
    text = text ++ "compiler:" ++ compiler_path ++ "\n"
    let files = ret_direct_w_files(fs, ret_dirname(entry))
    for i in 0..files.len() as i32:
        let path = files.get(i as i64)
        text = text ++ "file:" ++ path ++ "\n"
    text

fn ret_host_bin(path: str) -> str:
    if os() == "Windows":
        return path ++ ".exe"
    path

fn ret_append_test_marker(ctx: ActionCtx, combined: str, target_name: str, entry: str) -> str:
    let marker_path = "out/.build-state/" ++ target_name ++ ".test-pass"
    let fs = ctx.fs()
    let actual = fs.read_text(marker_path)
    if actual.len() == 0:
        ctx.diagnostics().error(ctx.target_name() ++ ": missing test pass marker " ++ marker_path ++ "; run `with build :test`")
        return ""
    let expected = ret_expected_test_marker(ctx, target_name, entry)
    if actual != expected:
        ctx.diagnostics().error(ctx.target_name() ++ ": stale test pass marker " ++ marker_path ++ "; run `with build :test`")
        return ""
    combined ++ "marker:" ++ target_name ++ "\n" ++ actual

fn ret_append_state_file(ctx: ActionCtx, combined: str, target_name: str) -> str:
    let state_path = "out/.build-state/" ++ target_name ++ ".state"
    let state = ctx.fs().read_text(state_path)
    if state.len() == 0:
        ctx.diagnostics().error(ctx.target_name() ++ ": missing build state " ++ state_path ++ "; run `with build :test`")
        return ""
    combined ++ "state:" ++ target_name ++ "\n" ++ state ++ "\n"

fn ret_sha256_files_manifest(ctx: ActionCtx, label: str, files: Vec[str]) -> str:
    if files.len() == 0:
        return ""
    let safe_label = ret_safe_label(label)
    let shasum_args: Vec[str] = Vec.new()
    shasum_args.push("shasum")
    shasum_args.push("-a")
    shasum_args.push("256")
    for i in 0..files.len() as i32:
        shasum_args.push(files.get(i as i64))
    let shasum = ret_run_lines(ctx, safe_label ++ "-shasum", shasum_args, 120000)
    if shasum.len() > 0:
        return ret_join_lines(shasum)
    let sha256_args: Vec[str] = Vec.new()
    sha256_args.push("sha256sum")
    for i in 0..files.len() as i32:
        sha256_args.push(files.get(i as i64))
    let sha256 = ret_run_lines(ctx, safe_label ++ "-sha256sum", sha256_args, 120000)
    ret_join_lines(sha256)

fn ret_append_file_hashes(combined: str, ctx: ActionCtx, label: str, files: Vec[str]) -> str:
    let manifest = ret_sha256_files_manifest(ctx, label, files)
    if files.len() > 0 and manifest.len() == 0:
        ctx.diagnostics().error(ctx.target_name() ++ ": could not hash " ++ label ++ " files")
        return ""
    combined ++ "files:" ++ label ++ "\n" ++ manifest

fn ret_build_driver_sources_manifest(ctx: ActionCtx) -> str:
    let fs = ctx.fs()
    let files: Vec[str] = Vec.new()
    files.push("build.w")
    let build_files = ret_sorted_strings(fs.list_files("build"))
    for i in 0..build_files.len() as i32:
        let path = build_files.get(i as i64)
        if path.ends_with(".w"):
            files.push(path)
    files.push("src/main.w")
    files.push("src/BuildGraphTests.w")
    files.push("src/BuildGraphCache.w")
    ret_append_file_hashes("", ctx, "build-driver", files)

fn ret_append_test_file_hashes(combined: str, ctx: ActionCtx, entry: str) -> str:
    let dir = ret_dirname(entry)
    let script = "if command -v shasum >/dev/null 2>&1; then find " ++ dir ++ " -maxdepth 1 -type f -name '*.w' -print | LC_ALL=C sort | xargs shasum -a 256; else find " ++ dir ++ " -maxdepth 1 -type f -name '*.w' -print | LC_ALL=C sort | xargs sha256sum; fi"
    let manifest = ret_join_lines(ret_shell_lines(ctx, ret_safe_label(entry) ++ "-files", script))
    if manifest.len() == 0:
        ctx.diagnostics().error(ctx.target_name() ++ ": could not hash " ++ entry ++ " files")
        return ""
    combined ++ "files:" ++ entry ++ "\n" ++ manifest

fn ret_test_green_fingerprint(ctx: ActionCtx) -> str:
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

fn ret_add_unique(items: Vec[str], item: str) -> Vec[str]:
    let out: Vec[str] = Vec.new()
    var found = item.len() == 0
    for i in 0..items.len() as i32:
        let existing = items.get(i as i64)
        if existing == item:
            found = true
        out.push(existing)
    if not found:
        out.push(item)
    out

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
        if fs.copy_file(ret_host_bin("out/bin/with"), archive) != 0:
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

pub fn run_test_green_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    if fs.mkdir_all("out/.build-state") != 0:
        return ret_fail(ctx, "could not create out/.build-state")
    let compiler_path = ret_host_bin("out/bin/with")
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
        "  \"test_inputs_fingerprint\": \"" ++ ret_json_escape(fingerprint) ++ "\"\n" ++
        "}\n"
    if fs.write_text("out/.build-state/test-green.json", manifest) != 0:
        return ret_fail(ctx, "could not write out/.build-state/test-green.json")
    print("[test-green] recorded current test evidence in out/.build-state/test-green.json")
    0

fn ret_require_test_green(ctx: ActionCtx, compiler_sha: str) -> i32:
    let manifest = ctx.fs().read_text("out/.build-state/test-green.json")
    if manifest.len() == 0:
        return ret_fail(ctx, "missing test-green manifest; run `with build :test`")
    let fingerprint = ret_test_green_fingerprint(ctx)
    if fingerprint.len() == 0:
        return 1
    let expected_compiler = "\"compiler_sha256\": \"" ++ compiler_sha ++ "\""
    if not manifest.contains(expected_compiler):
        return ret_fail(ctx, "test-green manifest was recorded for a different compiler; run `with build :test`")
    let expected_fingerprint = "\"test_inputs_fingerprint\": \"" ++ fingerprint ++ "\""
    if not manifest.contains(expected_fingerprint):
        return ret_fail(ctx, "test-green manifest is stale; run `with build :test`")
    0

pub fn run_last_green_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    if fs.mkdir_all("out/.build-state") != 0:
        return ret_fail(ctx, "could not create out/.build-state")
    let compiler_path = ret_host_bin("out/bin/with")
    if not fs.exists(compiler_path):
        return ret_fail(ctx, "missing " ++ compiler_path)
    let source_version = ret_first_line(fs.read_text("src/version"))
    let compiler_version = ret_compiler_version(ctx, compiler_path)
    if compiler_version.len() == 0:
        return ret_fail(ctx, "could not read verified compiler version")
    let compiler_sha = ret_sha256_file(ctx, "verified-compiler", compiler_path)
    if compiler_sha.len() == 0:
        return ret_fail(ctx, "could not hash " ++ compiler_path)
    if ret_require_test_green(ctx, compiler_sha) != 0:
        return 1
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

pub fn run_require_last_green_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let compiler_path = ret_host_bin("out/bin/with")
    if not fs.exists(compiler_path):
        return ret_fail(ctx, "missing " ++ compiler_path ++ "; run `with build` first")
    let manifest = fs.read_text("out/.build-state/last-green.json")
    if manifest.len() == 0:
        return ret_fail(ctx, "missing last-green manifest; run `with build :last-green` after build/fixpoint/test")
    let compiler_sha = ret_sha256_file(ctx, "verified-compiler-check", compiler_path)
    if compiler_sha.len() == 0:
        return ret_fail(ctx, "could not hash " ++ compiler_path)
    let expected = "\"compiler_sha256\": \"" ++ compiler_sha ++ "\""
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

fn ret_install_dest_abs(root: str, dest: str) -> str:
    if dest.starts_with("$HOME/"):
        let home = env("HOME")
        if home.len() == 0:
            return ""
        return ret_join(home, dest.slice(6, dest.len()))
    if dest.len() > 0 and dest.byte_at(0) == 47:
        return dest
    ret_abs(root, dest)

pub fn run_install_verified_compiler_action(ctx: ActionCtx) -> i32:
    let args = ctx.args()
    if args.len() < 3:
        return ret_fail(ctx, "requires source, destination, and mode args")
    let root = ctx.project_info().project_root()
    let source = args.get(0)
    let dest = args.get(1)
    let mode = args.get(2)
    let fs = ctx.fs()
    if not fs.exists(source):
        return ret_fail(ctx, "missing source compiler: " ++ source)
    let source_abs = ret_abs(root, source)
    let dest_abs = ret_install_dest_abs(root, dest)
    if dest_abs.len() == 0:
        return ret_fail(ctx, "could not resolve install destination: " ++ dest)
    let proc = ctx.process_runner()
    let mkdir_args: Vec[str] = Vec.new()
    mkdir_args.push("mkdir")
    mkdir_args.push("-p")
    mkdir_args.push(ret_dirname(dest_abs))
    let mkdir_rc = proc.run(mkdir_args)
    if mkdir_rc != 0:
        return ret_fail(ctx, "could not create install directory: " ++ ret_dirname(dest_abs))
    let copy_args: Vec[str] = Vec.new()
    copy_args.push("cp")
    copy_args.push(source_abs)
    copy_args.push(dest_abs)
    let copy_rc = proc.run(copy_args)
    if copy_rc != 0:
        return ret_fail(ctx, "could not copy compiler to " ++ dest)
    let chmod_args: Vec[str] = Vec.new()
    chmod_args.push("chmod")
    chmod_args.push(mode)
    chmod_args.push(dest_abs)
    let chmod_rc = proc.run(chmod_args)
    if chmod_rc != 0:
        return ret_fail(ctx, "could not chmod " ++ dest)
    let output = ctx.output()
    if output.len() > 0 and output != dest:
        let out_dir = ret_dirname(output)
        if fs.mkdir_all(out_dir) != 0:
            return ret_fail(ctx, "could not create " ++ out_dir)
        if fs.write_text(output, "ok\n") != 0:
            return ret_fail(ctx, "could not write " ++ output)
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

fn ret_add_stale_state_files(fs: ToolFs, live_targets: Vec[str], candidates: Vec[str]) -> Vec[str]:
    var out = candidates
    if live_targets.len() == 0 or not fs.exists("out/.build-state"):
        return out
    let files = fs.list_files("out/.build-state")
    for i in 0..files.len() as i32:
        let path = files.get(i as i64)
        let target_name = ret_state_target_name(path)
        if target_name.len() > 0 and not ret_vec_contains(live_targets, target_name):
            out = ret_add_unique(out, path)
    out

fn ret_add_old_seed_archives(fs: ToolFs, candidates: Vec[str]) -> Vec[str]:
    var out = candidates
    let entries = ret_seed_manifest_entries(fs)
    var keep_from = entries.len() as i32 - RET_SEED_KEEP
    if keep_from <= 0:
        return out
    for i in 0..keep_from:
        let path = entries.get(i as i64)
        if fs.exists(path):
            out = ret_add_unique(out, path)
    out

fn ret_release_artifact_version(path: str) -> str:
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

fn ret_release_artifact_versions(fs: ToolFs) -> Vec[str]:
    var versions: Vec[str] = Vec.new()
    if not fs.exists("out/release"):
        return versions
    let files = fs.list_files("out/release")
    for i in 0..files.len() as i32:
        let version = ret_release_artifact_version(files.get(i as i64))
        versions = ret_add_unique(versions, version)
    ret_sorted_release_versions(versions)

fn ret_stale_release_artifact_versions(fs: ToolFs) -> Vec[str]:
    let versions = ret_release_artifact_versions(fs)
    let stale: Vec[str] = Vec.new()
    let stale_count = versions.len() as i32 - RET_RELEASE_VERSION_KEEP
    if stale_count <= 0:
        return stale
    for i in 0..stale_count:
        stale.push(versions.get(i as i64))
    stale

fn ret_add_old_release_artifacts(fs: ToolFs, candidates: Vec[str]) -> Vec[str]:
    var out = candidates
    let stale_versions = ret_stale_release_artifact_versions(fs)
    if stale_versions.len() == 0 or not fs.exists("out/release"):
        return out
    let files = fs.list_files("out/release")
    for i in 0..files.len() as i32:
        let path = files.get(i as i64)
        let version = ret_release_artifact_version(path)
        if ret_vec_contains(stale_versions, version):
            out = ret_add_unique(out, path)
    out

fn ret_small_prune_candidates(ctx: ActionCtx) -> Vec[str]:
    let fs = ctx.fs()
    var candidates: Vec[str] = Vec.new()
    candidates = ret_add_stale_state_files(fs, ret_live_targets(ctx.args()), candidates)
    candidates = ret_add_old_seed_archives(fs, candidates)
    candidates = ret_add_old_release_artifacts(fs, candidates)
    ret_sorted_strings(candidates)

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
    print(f"[prune] removed {removed} stale retained artifact(s)")
    0

fn ret_apply_large_prune(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let bin_count = ret_shell_first_line(ctx, "apply-count-temp-bin", "if [ -d out/bin ]; then find out/bin -maxdepth 1 \\( -type d -name '*.tmp.*.dSYM' -o -type f -name '*.tmp.*' \\) -print | wc -l; else echo 0; fi")
    let lib_count = ret_shell_first_line(ctx, "apply-count-temp-lib-archives", "if [ -d out/lib ]; then find out/lib -maxdepth 1 -type f -name '*.o.*.a' -print | wc -l; else echo 0; fi")
    let bootstrap_count = ret_shell_first_line(ctx, "apply-count-temp-bootstrap-archives", "if [ -d out/bootstrap-lib ]; then find out/bootstrap-lib -maxdepth 1 -type f -name '*.o.*.a' -print | wc -l; else echo 0; fi")
    let issue61_count = ret_shell_first_line(ctx, "apply-count-issue61-stale", "if [ -d out/test-graph/issue61-regression ]; then find out/test-graph/issue61-regression -mindepth 1 -maxdepth 1 -type d ! -name repo -print | wc -l; else echo 0; fi")
    let embedded_compiler_count = ret_shell_first_line(ctx, "apply-count-embedded-compiler", "if [ -f out/test-graph/embedded-runtime-regression/with ]; then echo 1; else echo 0; fi")
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
    if fs.exists("out/test-graph/issue61-regression"):
        let issue61_args: Vec[str] = Vec.new()
        issue61_args.push("find")
        issue61_args.push("out/test-graph/issue61-regression")
        issue61_args.push("-mindepth")
        issue61_args.push("1")
        issue61_args.push("-maxdepth")
        issue61_args.push("1")
        issue61_args.push("-type")
        issue61_args.push("d")
        issue61_args.push("!")
        issue61_args.push("-name")
        issue61_args.push("repo")
        issue61_args.push("-exec")
        issue61_args.push("rm")
        issue61_args.push("-rf")
        issue61_args.push("{}")
        issue61_args.push("+")
        if ret_run_status(ctx, "delete-issue61-stale", issue61_args, 300000) != 0:
            return 1
    if fs.exists("out/test-graph/embedded-runtime-regression/with"):
        if fs.remove_file("out/test-graph/embedded-runtime-regression/with") != 0:
            return ret_fail(ctx, "could not remove retained embedded-runtime copied compiler")
    print("[prune] removed temp out/bin entries: " ++ ret_trim(bin_count))
    print("[prune] removed temp out/lib archives: " ++ ret_trim(lib_count))
    print("[prune] removed temp out/bootstrap-lib archives: " ++ ret_trim(bootstrap_count))
    print("[prune] removed stale issue61 regression directories: " ++ ret_trim(issue61_count))
    print("[prune] removed retained embedded runtime compiler copies: " ++ ret_trim(embedded_compiler_count))
    0

fn ret_report_prune(candidates: Vec[str]):
    print(f"[prune] {candidates.len()} stale state/seed/release artifact(s) would be removed")
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
    let issue61_count = ret_shell_first_line(ctx, "count-issue61-stale", "if [ -d out/test-graph/issue61-regression ]; then find out/test-graph/issue61-regression -mindepth 1 -maxdepth 1 -type d ! -name repo -print | wc -l; else echo 0; fi")
    let embedded_compiler_count = ret_shell_first_line(ctx, "count-embedded-compiler", "if [ -f out/test-graph/embedded-runtime-regression/with ]; then echo 1; else echo 0; fi")
    print("[prune] temp out/bin entries: " ++ ret_trim(bin_count))
    print("[prune] temp out/lib archives: " ++ ret_trim(lib_count))
    print("[prune] temp out/bootstrap-lib archives: " ++ ret_trim(bootstrap_count))
    print("[prune] stale issue61 regression directories: " ++ ret_trim(issue61_count))
    print("[prune] retained embedded runtime compiler copies: " ++ ret_trim(embedded_compiler_count))
    let examples = ret_shell_lines(ctx, "sample-temp-artifacts", "if [ -d out/bin ]; then find out/bin -maxdepth 1 \\( -type d -name '*.tmp.*.dSYM' -o -type f -name '*.tmp.*' \\) -print; fi; if [ -d out/lib ]; then find out/lib -maxdepth 1 -type f -name '*.o.*.a' -print | sed -n '1,30p'; fi; if [ -d out/bootstrap-lib ]; then find out/bootstrap-lib -maxdepth 1 -type f -name '*.o.*.a' -print | sed -n '1,10p'; fi; if [ -d out/test-graph/issue61-regression ]; then find out/test-graph/issue61-regression -mindepth 1 -maxdepth 1 -type d ! -name repo -print | sed -n '1,10p'; fi; if [ -f out/test-graph/embedded-runtime-regression/with ]; then echo out/test-graph/embedded-runtime-regression/with; fi")
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
