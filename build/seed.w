module build.seed

use std.build
use std.process
use build.compiler
fn seed_owned_text(s: &str): s ++ ""

fn seed_join(left: &str, right: &str) -> str:
    if left.len() == 0:
        return seed_owned_text(right)
    if right.len() == 0:
        return seed_owned_text(left)
    if left.ends_with("/"):
        return left ++ right
    left ++ "/" ++ right

fn seed_dirname(path: &str) -> str:
    var last_slash = -1
    for i in 0..path.len() as i32:
        if path[i] == 47:
            last_slash = i
    if last_slash < 0:
        return "."
    if last_slash == 0:
        return "/"
    path.slice(0, last_slash as i64)

fn seed_abs(root: &str, path: &str) -> str:
    if path.len() > 0 and path[0] == 47:
        return seed_owned_text(path)
    seed_join(root, path)

fn seed_fail(ctx: &ActionCtx, message: &str) -> i32:
    ctx.diagnostics().error(ctx.target_name() ++ ": " ++ message)
    1

fn seed_split_nonempty_lines(text: &str) -> Vec[str]:
    let lines: Vec[str] = Vec.new()
    var start = 0
    for i in 0..text.len() as i32:
        if text[i] == 10:
            if i > start:
                lines.push(text.slice(start as i64, i as i64))
            start = i + 1
    if start < text.len() as i32:
        lines.push(text.slice(start as i64, text.len()))
    lines

fn seed_json_line_value(line: &str, key: &str) -> str:
    let needle = "\"" ++ key ++ "\""
    var pos = -1
    var i = 0
    while i <= line.len() as i32 - needle.len() as i32:
        if line.slice(i as i64, (i + needle.len() as i32) as i64) == needle:
            pos = i + needle.len() as i32
            break
        i = i + 1
    if pos < 0:
        return ""
    while pos < line.len() as i32:
        let ch = line[pos]
        if ch != 32 and ch != 9:
            break
        pos = pos + 1
    if pos >= line.len() as i32 or line[pos] != 58:
        return ""
    pos = pos + 1
    while pos < line.len() as i32:
        let ch = line[pos]
        if ch != 32 and ch != 9:
            break
        pos = pos + 1
    if pos >= line.len() as i32 or line[pos] != 34:
        return ""
    let start = pos + 1
    var end = start
    var escaped = false
    while end < line.len() as i32:
        let ch = line[end]
        if escaped:
            escaped = false
        else if ch == 92:
            escaped = true
        else if ch == 34:
            return line.slice(start as i64, end as i64)
        end = end + 1
    ""

fn seed_compile_binary(ctx: &ActionCtx, workspace_name: &str, source_path: &str, output_path: &str) -> i32:
    let workspace = ctx.create_workspace(workspace_name)
    workspace.add_file(source_path)
    var options = workspace.options()
    options.output_path = seed_owned_text(output_path)
    workspace.set_options(options)
    let result = workspace.compile()
    if result.rc != 0:
        return seed_fail(ctx, workspace_name ++ f" failed with exit code {result.rc}")
    if not ctx.fs().exists(output_path):
        return seed_fail(ctx, workspace_name ++ " did not produce " ++ output_path)
    0

fn seed_fetch_to_file(ctx: &ActionCtx, scratch_dir: &str, label: &str, url: &str, output_path: &str, timeout_ms: i32) -> i32:
    let fs = ctx.fs()
    let root = ctx.project_info().project_root()
    let fetch_bin = seed_join(scratch_dir, "https_fetch")
    if fs.mkdir_all(seed_dirname(fetch_bin)) != 0:
        return seed_fail(ctx, "could not create HTTPS fetch helper directory")
    var rc = seed_compile_binary(ctx, label ++ "-https-fetch-helper", "build/https_fetch.w", fetch_bin)
    if rc != 0:
        return rc
    var fetch_args: Vec[str] = Vec.new()
    fetch_args.push(seed_abs(root, fetch_bin))
    fetch_args.push(seed_owned_text(url))
    fetch_args.push(seed_abs(root, output_path))
    let result = ctx.process_runner().run_capture(fetch_args, seed_abs(root, seed_join(scratch_dir, label ++ ".fetch.stdout")), seed_abs(root, seed_join(scratch_dir, label ++ ".fetch.stderr")), timeout_ms)
    if result.rc != 0:
        return seed_fail(ctx, f"HTTPS fetch helper failed with exit code {result.rc}: " ++ result.stdout ++ result.stderr)
    0

fn seed_gunzip_to_tar(ctx: &ActionCtx, scratch_dir: &str, archive_path: &str, tar_path: &str) -> i32:
    let fs = ctx.fs()
    let root = ctx.project_info().project_root()
    let gunzip_bin = seed_join(scratch_dir, "zlib_gunzip")
    if fs.mkdir_all(seed_dirname(gunzip_bin)) != 0:
        return seed_fail(ctx, "could not create gunzip helper directory")
    var rc = seed_compile_binary(ctx, "deps-gunzip-helper", "build/zlib_gunzip.w", gunzip_bin)
    if rc != 0:
        return rc
    var gunzip_args: Vec[str] = Vec.new()
    gunzip_args.push(seed_abs(root, gunzip_bin))
    gunzip_args.push(seed_abs(root, archive_path))
    gunzip_args.push(seed_abs(root, tar_path))
    let result = ctx.process_runner().run_capture(gunzip_args, seed_abs(root, seed_join(scratch_dir, "gunzip.stdout")), seed_abs(root, seed_join(scratch_dir, "gunzip.stderr")), 300000)
    if result.rc != 0:
        return seed_fail(ctx, f"gunzip helper failed with exit code {result.rc}: " ++ result.stdout ++ result.stderr)
    0

fn seed_release_from_api(ctx: &ActionCtx, repo: &str, asset_name: &str) -> str:
    let fs = ctx.fs()
    let tmp_dir = seed_join("out/tmp", "seed-download")
    if fs.mkdir_all(tmp_dir) != 0:
        return ""
    let body_path = seed_join(tmp_dir, "releases.json")
    let fetch_rc = seed_fetch_to_file(ctx, tmp_dir, "release-api", "https://api.github.com/repos/" ++ repo ++ "/releases?per_page=10", body_path, 120000)
    if fetch_rc != 0:
        return ""
    let body = fs.read_text(body_path)
    let _remove_body = fs.remove_file(body_path)
    let lines = seed_split_nonempty_lines(body)
    var current_tag = ""
    for li in 0..lines.len() as i32:
        let line = lines[li]
        let tag = seed_json_line_value(line, "tag_name")
        if tag.len() > 0:
            current_tag = tag
        let name = seed_json_line_value(line, "name")
        if current_tag.len() > 0 and name == asset_name:
            return current_tag
    ""

fn seed_is_space(ch: i32) -> bool:
    ch == 9 or ch == 10 or ch == 13 or ch == 32

fn seed_is_hex(ch: i32) -> bool:
    (ch >= 48 and ch <= 57) or (ch >= 65 and ch <= 70) or (ch >= 97 and ch <= 102)

fn seed_parse_sha256_sidecar(text: &str) -> str:
    var start = 0
    while start < text.len() as i32 and seed_is_space(text[start]):
        start = start + 1
    var end = start
    while end < text.len() as i32 and not seed_is_space(text[end]):
        if not seed_is_hex(text[end]):
            return ""
        end = end + 1
    if end - start != 64:
        return ""
    text.slice(start as i64, end as i64)

fn seed_fetch_expected_sha256(ctx: &ActionCtx, tmp_dir: &str, label: &str, asset_url: &str) -> str:
    let fs = ctx.fs()
    let sidecar_path = seed_join(tmp_dir, label ++ ".sha256")
    let _remove_sidecar = fs.remove_file(sidecar_path)
    let rc = seed_fetch_to_file(ctx, tmp_dir, label ++ "-sha256", asset_url ++ ".sha256", sidecar_path, 120000)
    if rc != 0:
        return ""
    let expected = seed_parse_sha256_sidecar(fs.read_text(sidecar_path))
    let _cleanup_sidecar = fs.remove_file(sidecar_path)
    if expected.len() == 0:
        ctx.diagnostics().error(ctx.target_name() ++ ": invalid SHA-256 sidecar for " ++ asset_url)
    expected

fn seed_verify_download_sha256(ctx: &ActionCtx, tmp_dir: &str, label: &str, asset_url: &str, path: &str) -> i32:
    let expected = seed_fetch_expected_sha256(ctx, tmp_dir, label, asset_url)
    if expected.len() == 0:
        return seed_fail(ctx, "missing or invalid SHA-256 sidecar: " ++ asset_url ++ ".sha256")
    let actual = ctx.fs().sha256_file(path)
    if actual.len() == 0:
        return seed_fail(ctx, "could not hash downloaded asset: " ++ path)
    if actual != expected:
        let _remove_bad = ctx.fs().remove_file(path)
        return seed_fail(ctx, "sha256 mismatch for " ++ asset_url ++ ": expected " ++ expected ++ " got " ++ actual)
    0

pub fn run_seed_download_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let args = ctx.args()
    let output_path = ctx.output()
    let root = ctx.project_info().project_root()
    if args.len() < 2 or output_path.len() == 0:
        return seed_fail(ctx, "requires repo arg, asset arg, and output path")
    let repo = args.get(0)
    let asset_name = args.get(1)
    let lock = seed_lock_read(fs)
    let pinned = seed_lock_value(lock, asset_name)
    var tag = env("SEED_VERSION")
    // The pinned seed (seed.lock) before "the newest release": the newest
    // release is not always able to build this tree, the pinned one is.
    if tag.len() == 0 and lock.len() > 0:
        tag = seed_lock_version_for(lock, asset_name)
        if tag.len() > 0: print("pinned seed release (seed.lock): " ++ tag)
    // Idempotent on the pin: src/main is the pinned seed, so a bump of
    // seed.lock refetches and an unchanged lock is a no-op. A binary that is
    // not the pinned one (a stale seed, a fresh compiler copied by hand) is
    // replaced, never kept.
    if fs.exists(output_path):
        if pinned.len() == 64 and tag.len() > 0 and fs.sha256_file(output_path) == pinned:
            print(output_path ++ " is the pinned seed " ++ tag)
            return 0
        print(output_path ++ " is not the pinned seed; refetching")
        if fs.remove_file(output_path) != 0:
            return seed_fail(ctx, "could not remove " ++ output_path)
    if tag.len() == 0:
        tag = seed_release_from_api(ctx, repo, asset_name)
        if tag.len() == 0:
            ctx.diagnostics().error("seed: could not find a release containing asset '" ++ asset_name ++ "'")
            ctx.diagnostics().error("set SEED_VERSION to a release tag to download a specific seed")
            return 1
        print("latest seed release: " ++ tag)
    let url = "https://github.com/" ++ repo ++ "/releases/download/" ++ tag ++ "/" ++ asset_name
    let output_dir = seed_dirname(output_path)
    if fs.mkdir_all(output_dir) != 0:
        return seed_fail(ctx, "could not create output directory: " ++ output_dir)
    let tmp_dir = seed_join("out/tmp", "seed-download")
    if fs.mkdir_all(tmp_dir) != 0:
        return seed_fail(ctx, "could not create temp directory: " ++ tmp_dir)
    let tmp_path = seed_join(tmp_dir, asset_name ++ ".tmp")
    let _remove_tmp = fs.remove_file(tmp_path)
    print("downloading seed from: " ++ url)
    let fetch_rc = seed_fetch_to_file(ctx, tmp_dir, "seed-asset", url, tmp_path, 300000)
    if fetch_rc != 0:
        return fetch_rc
    let verify_rc = seed_verify_download_sha256(ctx, tmp_dir, "seed-asset", url, tmp_path)
    if verify_rc != 0:
        return verify_rc
    // The sidecar proves the download; the lock proves it is the pinned seed.
    if pinned.len() == 64 and env("SEED_VERSION").len() == 0:
        let actual = fs.sha256_file(tmp_path)
        if actual != pinned:
            let _remove_bad = fs.remove_file(tmp_path)
            return seed_fail(ctx, asset_name ++ " " ++ tag ++ " digest " ++ actual ++ " does not match seed.lock's " ++ pinned)
    if fs.rename(tmp_path, output_path) != 0:
        return seed_fail(ctx, "could not publish seed: " ++ output_path)
    if fs.chmod(output_path, 0o755) != 0:
        return seed_fail(ctx, "could not chmod seed: " ++ output_path)
    print("seed installed: " ++ output_path)
    0

// Fetch the pinned, per-platform static LLVM/Clang/lld SDK that bootstrap built
// and a release published, instead of rebuilding LLVM from source or trusting a
// system LLVM. Mirrors run_seed_download_action, plus tar.gz extraction into
// `.deps/<sdk_base>`. Args: repo, asset_name, sdk_base (= "llvm-<ver>-<host>").
// Output: the SDK marker `.deps/<sdk_base>/lib/libclang.a` or `libclang.lib`.
pub fn run_deps_download_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let args = ctx.args()
    let marker = ctx.output()
    if args.len() < 3 or marker.len() == 0:
        return seed_fail(ctx, "requires repo arg, asset arg, sdk-base arg, and marker output")
    let repo = args.get(0)
    let asset_name = args.get(1)
    let sdk_base = args.get(2)
    if fs.exists(marker):
        print("static LLVM SDK already present: " ++ seed_join(".deps", sdk_base))
        return 0

    var tag = env("WITH_LLVM_SDK_VERSION")
    if tag.len() == 0:
        tag = seed_release_from_api(ctx, repo, asset_name)
        if tag.len() == 0:
            ctx.diagnostics().error("deps: could not find a release containing asset '" ++ asset_name ++ "'")
            ctx.diagnostics().error("set WITH_LLVM_SDK_VERSION to a release tag, or build it from source: tools/build-static-llvm.sh")
            return 1
        print("latest SDK release: " ++ tag)

    let url = "https://github.com/" ++ repo ++ "/releases/download/" ++ tag ++ "/" ++ asset_name
    let tmp_dir = seed_join("out/tmp", "deps-download")
    if fs.mkdir_all(tmp_dir) != 0:
        return seed_fail(ctx, "could not create temp directory: " ++ tmp_dir)
    let archive_path = seed_join(tmp_dir, asset_name)
    let _remove_archive = fs.remove_file(archive_path)
    print("downloading static LLVM SDK from: " ++ url)
    let fetch_rc = seed_fetch_to_file(ctx, tmp_dir, "deps-asset", url, archive_path, 900000)
    if fetch_rc != 0:
        return fetch_rc
    let verify_rc = seed_verify_download_sha256(ctx, tmp_dir, "deps-asset", url, archive_path)
    if verify_rc != 0:
        return verify_rc

    if not asset_name.ends_with(".tar.gz"):
        return seed_fail(ctx, "unsupported SDK archive format (expected .tar.gz): " ++ asset_name)
    let tar_path = seed_join(tmp_dir, sdk_base ++ ".tar")
    let _remove_tar = fs.remove_file(tar_path)
    let gunzip_rc = seed_gunzip_to_tar(ctx, tmp_dir, archive_path, tar_path)
    if gunzip_rc != 0:
        return gunzip_rc

    let extract_dir = seed_join(tmp_dir, "extract")
    if fs.exists(extract_dir) and fs.remove_tree(extract_dir) != 0:
        return seed_fail(ctx, "could not remove old extract directory: " ++ extract_dir)
    if fs.mkdir_all(extract_dir) != 0:
        return seed_fail(ctx, "could not create extract directory: " ++ extract_dir)
    if fs.extract_tar(tar_path, extract_dir) != 0:
        return seed_fail(ctx, "tar extraction failed for " ++ tar_path)

    let extracted_sdk = seed_join(extract_dir, sdk_base)
    if not fs.is_dir(extracted_sdk):
        return seed_fail(ctx, "archive did not contain expected SDK directory: " ++ sdk_base)
    let target_dir = seed_join(".deps", sdk_base)
    if fs.mkdir_all(".deps") != 0:
        return seed_fail(ctx, "could not create .deps directory")
    if fs.exists(target_dir) and fs.remove_tree(target_dir) != 0:
        return seed_fail(ctx, "could not remove existing SDK directory: " ++ target_dir)
    if fs.rename(extracted_sdk, target_dir) != 0:
        return seed_fail(ctx, "could not move SDK into place: " ++ target_dir)
    let _cleanup_tar = fs.remove_file(tar_path)
    let _cleanup_extract = fs.remove_tree(extract_dir)
    if not fs.exists(marker):
        return seed_fail(ctx, "SDK installed but missing expected archive: " ++ marker)
    print("static LLVM SDK installed: " ++ target_dir)
    0

// ── seed.lock and the pinned driver ─────────────────────────────────────────
// CI drives `build` and `:test` with the seed pinned in seed.lock, so every
// action body in build.w and build/*.w is comptime-evaluated by that
// released compiler. The local battery is driven the same way: `with build
// :seed` keeps src/main at the pinned asset, `WITH=$PWD/src/main src/main
// build ...` runs the battery, and `seed-driver` (build/retention.w) refuses
// `:test`, `:test-green` and `:last-green` under any other driver — the Rust
// and Go rule (the pinned stage0 builds `bootstrap`; `GOROOT_BOOTSTRAP` builds
// `cmd/dist`). Before this, the battery ended in `:update-seed`, the local
// seed chased the tree, and features only the fresh compiler had passed
// locally and broke CI (2026-09-02..04, #1143). The workflow pins must equal
// the lock, so the pin can only move in one place.

/// The text of seed.lock; "" when the tree has none.
pub fn seed_lock_read(fs: &ToolFs) -> str:
    if fs.exists("seed.lock"): fs.read_text("seed.lock") else: ""

/// One `key=value` line of seed.lock; "" when the key is absent.
pub fn seed_lock_value(lock: &str, key: &str) -> str:
    for line in lock.split("\n"):
        let l = line.trim()
        if l.starts_with("#") or l.len() == 0: continue
        let eq = l.index_of("=")
        if eq > 0 and l.slice(0, eq) == key: return l.slice(eq + 1, l.len())
    ""

/// The seed version an asset is pinned to: `<asset>.version=` when the lock
/// carries one (a platform that cannot bootstrap the newest seed yet — say
/// which issue in the lock's comment), else `version=`.
pub fn seed_lock_version_for(lock: &str, asset: &str) -> str:
    let own = seed_lock_value(lock, asset ++ ".version")
    if own.len() > 0: own else: seed_lock_value(lock, "version")

/// The asset named by the pin block that starts at `lines[i]` (a version
/// line): the `seed_asset:`/`WITH_SEED_ASSET:` line within the next few
/// lines — every block shape we have names the asset after the version and
/// before the digest.
fn seed_lock_block_asset(lines: &Vec[str], i: i64) -> str:
    var j = i + 1
    while j < lines.len() and j <= i + 4:
        let line = lines.get(j)
        for akey in ["seed_asset:", "WITH_SEED_ASSET:"]:
            let at = line.index_of(akey)
            if at >= 0: return line.slice(at + akey.len(), line.len()).trim()
        j = j + 1
    ""

/// The workflow files whose seed pins must equal seed.lock, with the lines
/// that disagree ("file:line: <line>"), empty when all agree. A version line
/// is checked against its block's asset (see seed_lock_block_asset), a
/// digest line against the asset named since.
pub fn seed_lock_workflow_drift(fs: &ToolFs, lock: &str) -> Vec[str]:
    var drift: Vec[str] = Vec.new()
    let dir = ".github/workflows"
    for path in fs.list_files(dir):
        if not path.ends_with(".yml"): continue
        let lines = fs.read_text(path).split("\n")
        var pending_asset = ""
        for i in 0..lines.len():
            let line = lines.get(i)
            let nr = i + 1
            if line.contains("${{"): continue
            for akey in ["seed_asset:", "WITH_SEED_ASSET:"]:
                let at = line.index_of(akey)
                if at >= 0: pending_asset = line.slice(at + akey.len(), line.len()).trim()
            for vkey in ["seed_version:", "WITH_SEED_VERSION:"]:
                let at = line.index_of(vkey)
                if at >= 0:
                    // The block's asset: named after the version in the matrix
                    // and most env blocks, before it in selfhost-linux-aarch64.
                    var asset = seed_lock_block_asset(&lines, i)
                    if asset.len() == 0: asset = pending_asset ++ ""
                    if line.slice(at + vkey.len(), line.len()).trim() != seed_lock_version_for(lock, asset):
                        drift.push(f"{path}:{nr}: {line}")
            for skey in ["seed_sha256:", "WITH_SEED_SHA256:"]:
                let at = line.index_of(skey)
                if at >= 0 and line.slice(at + skey.len(), line.len()).trim() != seed_lock_value(lock, pending_asset):
                    drift.push(f"{path}:{nr}: {line}")
    drift
