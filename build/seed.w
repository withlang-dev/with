module build.seed

use std.build
use std.process
use build.compiler
use build.source_fetch
use std.io.print_str
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

fn seed_split_nonempty_lines(text: &str) -> List[str]:
    let lines: List[str] = List.new()
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

// One https fetch through build/source_fetch.w (#2062): a host that is down
// is reported within SOURCE_FETCH_CONNECT_MS, and one that connects and says
// nothing at `timeout_ms`, each naming the URL.
fn seed_fetch_to_file(ctx: &ActionCtx, scratch_dir: &str, label: &str, url: &str, output_path: &str, timeout_ms: i32) -> i32:
    let fetched = source_fetch_url(ctx, scratch_dir, label, url, output_path, SOURCE_FETCH_CONNECT_MS, timeout_ms)
    if fetched.rc != 0:
        return seed_fail(ctx, fetched.report)
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
    var gunzip_args: List[str] = List.new()
    gunzip_args.push(seed_abs(root, gunzip_bin))
    gunzip_args.push(seed_abs(root, archive_path))
    gunzip_args.push(seed_abs(root, tar_path))
    let result = ctx.process_runner().run_capture(gunzip_args, seed_abs(root, seed_join(scratch_dir, "gunzip.stdout")), seed_abs(root, seed_join(scratch_dir, "gunzip.stderr")), 300000)
    if result.rc != 0:
        return seed_fail(ctx, f"gunzip helper failed with exit code {result.rc}: " ++ result.stdout ++ result.stderr)
    0

// #1888: which release carries `asset_name` — the newest one, searched page
// by page (100 releases a page, at most SEED_RELEASE_PAGES pages; one page of
// 10 lost the darwin SDK as soon as ten newer nightlies sat on top of it,
// and lost the windows-aarch64 SDK outright). Every response is kept under
// out/tmp/seed-download/releases-<page>.json, and a miss says which it was:
// the request failed, the response was not a release list, or none of the
// releases scanned carries the asset. The scan reads the body as one text,
// not by lines: each release's assets follow its tag_name.
type SeedReleaseLookup { tag: str, why: str }

const SEED_RELEASE_PAGES: i32 = 10

fn seed_release_from_api(ctx: &ActionCtx, repo: &str, asset_name: &str) -> SeedReleaseLookup:
    let fs = ctx.fs()
    let tmp_dir = seed_join("out/tmp", "seed-download")
    if fs.mkdir_all(tmp_dir) != 0:
        return SeedReleaseLookup { tag: "", why: "could not create " ++ tmp_dir }
    let quoted_asset = "\"" ++ asset_name ++ "\""
    var scanned = 0
    for page in 1..SEED_RELEASE_PAGES + 1:
        let body_path = seed_join(tmp_dir, f"releases-{page}.json")
        let url = "https://api.github.com/repos/" ++ repo ++ f"/releases?per_page=100&page={page}"
        if seed_fetch_to_file(ctx, tmp_dir, "release-api", url, body_path, 120000) != 0:
            return SeedReleaseLookup { tag: "", why: "the release list request failed: " ++ url }
        let body = fs.read_text(body_path)
        let releases = body.split("\"tag_name\"")
        if releases.len() < 2:
            if seed_is_empty_json_array(body): break
            return SeedReleaseLookup { tag: "", why: "the response to " ++ url ++ " is not a release list (kept at " ++ body_path ++ ")" }
        for ri in 1..releases.len() as i32:
            scanned = scanned + 1
            let release = releases[ri]
            if release.contains(quoted_asset):
                let tag = seed_json_line_value("\"tag_name\"" ++ release, "tag_name")
                if tag.len() == 0:
                    return SeedReleaseLookup { tag: "", why: "a release carrying the asset has no readable tag_name (kept at " ++ body_path ++ ")" }
                return SeedReleaseLookup { tag: tag, why: "" }
        if releases.len() - 1 < 100: break
    SeedReleaseLookup { tag: "", why: f"none of the {scanned} newest releases of " ++ repo ++ " carries it (responses kept under " ++ tmp_dir ++ ")" }

fn seed_is_empty_json_array(text: &str) -> bool:
    var inner = ""
    for i in 0..text.len() as i32:
        let ch = text[i]
        if not seed_is_space(ch): inner = inner ++ text.slice(i as i64, (i + 1) as i64)
    inner == "[]"

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
    let repo = args[0]
    let asset_name = args[1]
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
        // #1667: the stale binary stays until the pinned one is downloaded
        // and verified — it may be the very compiler driving this action
        // (`WITH=$PWD/src/main src/main build :seed`), which still has to
        // compile the fetch helper. Removing it first left no seed at all
        // when the helper's build then failed (exit 127).
        print(output_path ++ " is not the pinned seed; refetching")
    if tag.len() == 0:
        var lookup = seed_release_from_api(ctx, repo, asset_name)
        if lookup.tag.len() == 0:
            return seed_fail(ctx, "seed: could not find a release containing asset '" ++ asset_name ++ "': " ++ lookup.why ++ "\nset SEED_VERSION to a release tag to download a specific seed")
        tag = move lookup.tag
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
    // Only now does the old seed go: the replacement is verified and beside it.
    if fs.exists(output_path) and fs.remove_file(output_path) != 0:
        return seed_fail(ctx, "could not remove " ++ output_path)
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
    let repo = args[0]
    let asset_name = args[1]
    let sdk_base = args[2]
    let sdk_dir = seed_join(".deps", sdk_base)
    // sdk.lock pins the SDK (#1826): a present SDK is kept only when its
    // stamp says it is the pinned release and digest, so a bump of the lock
    // refetches and an SDK fetched before the pin existed is replaced.
    // WITH_LLVM_SDK_VERSION asks for another release by hand and keeps the
    // unpinned behavior.
    let lock = sdk_lock_read(fs)
    let pin = llvm_sdk_pin(lock, asset_name)
    let override_tag = env("WITH_LLVM_SDK_VERSION")
    let pinned = pin.len() > 0 and override_tag.len() == 0
    let stamp_path = llvm_sdk_pin_stamp_path(sdk_dir)
    if fs.exists(marker):
        if not pinned:
            print_str("static LLVM SDK already present: " ++ sdk_dir ++ "\n")
            return 0
        if fs.exists(stamp_path) and fs.read_text(stamp_path) == pin ++ "\n":
            print_str(sdk_dir ++ " is the pinned SDK " ++ pin ++ "\n")
            return 0
        print_str(sdk_dir ++ " is not the pinned SDK " ++ pin ++ " (sdk.lock); refetching\n")

    var tag = override_tag.clone()
    if pinned:
        tag = lock_value(lock, asset_name ++ ".version")
        print_str("pinned SDK release (sdk.lock): " ++ tag ++ "\n")
    if tag.len() == 0:
        var lookup = seed_release_from_api(ctx, repo, asset_name)
        if lookup.tag.len() == 0:
            return seed_fail(ctx, "deps: could not find a release containing asset '" ++ asset_name ++ "': " ++ lookup.why ++ "\nset WITH_LLVM_SDK_VERSION to a release tag, or build it from source: tools/build-static-llvm.sh")
        tag = move lookup.tag
        print_str("latest SDK release: " ++ tag ++ "\n")

    let url = "https://github.com/" ++ repo ++ "/releases/download/" ++ tag ++ "/" ++ asset_name
    let tmp_dir = seed_join("out/tmp", "deps-download")
    if fs.mkdir_all(tmp_dir) != 0:
        return seed_fail(ctx, "could not create temp directory: " ++ tmp_dir)
    let archive_path = seed_join(tmp_dir, asset_name)
    let _remove_archive = fs.remove_file(archive_path)
    print_str("downloading static LLVM SDK from: " ++ url ++ "\n")
    let fetch_rc = seed_fetch_to_file(ctx, tmp_dir, "deps-asset", url, archive_path, 900000)
    if fetch_rc != 0:
        return fetch_rc
    let verify_rc = seed_verify_download_sha256(ctx, tmp_dir, "deps-asset", url, archive_path)
    if verify_rc != 0:
        return verify_rc
    // The release's own sidecar says the upload is intact; the lock says it
    // is the SDK this tree was verified with. A release asset replaced in
    // place passes the first and fails here.
    if pinned:
        let actual = fs.sha256_file(archive_path)
        let expected = lock_value(lock, asset_name)
        if actual != expected:
            let _remove_unpinned = fs.remove_file(archive_path)
            return seed_fail(ctx, "sha256 of " ++ url ++ " is " ++ actual ++ ", not the " ++ expected ++ " sdk.lock pins: the release asset was replaced; pin the new digest only after verifying it")

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
    if pinned and fs.write_text(stamp_path, pin ++ "\n") != 0:
        return seed_fail(ctx, "could not write " ++ stamp_path)
    print_str("static LLVM SDK installed: " ++ target_dir ++ "\n")
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
pub fn seed_lock_value(lock: &str, key: &str) -> str: lock_value(lock, key)

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
fn seed_lock_block_asset(lines: &List[str], i: i64) -> str:
    var j = i + 1
    while j < lines.len() and j <= i + 4:
        let line = lines[j]
        for akey in ["seed_asset:", "WITH_SEED_ASSET:"]:
            let at = line.index_of(akey)
            if at >= 0: return line.slice(at + akey.len(), line.len()).trim().to_owned()
        j = j + 1
    ""

/// The workflow files whose seed pins must equal seed.lock, with the lines
/// that disagree ("file:line: <line>"), empty when all agree. A version line
/// is checked against its block's asset (see seed_lock_block_asset), a
/// digest line against the asset named since.
pub fn seed_lock_workflow_drift(fs: &ToolFs, lock: &str) -> List[str]:
    var drift: List[str] = List.new()
    let dir = ".github/workflows"
    for path in fs.list_files(dir):
        if not path.ends_with(".yml"): continue
        let lines = fs.read_text(path).split("\n")
        var pending_asset = ""
        for i in 0..lines.len():
            let line = lines[i]
            let nr = i + 1
            if line.contains("${{"): continue
            for akey in ["seed_asset:", "WITH_SEED_ASSET:"]:
                let at = line.index_of(akey)
                if at >= 0: pending_asset = line.slice(at + akey.len(), line.len()).trim().to_owned()  // #2307: owned until the seed copies interior views
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

/// The workflow LLVM SDK pins that disagree with sdk.lock ("file:line:
/// <line>"), empty when all agree (#1826). A release line is checked against
/// the asset its block names; the archive, sidecar and manifest digests
/// against `<asset>=`, `<asset>.sha256=` and `<asset>.manifest=` of the
/// asset named since. An asset a workflow pins that the lock does not is
/// drift too: the lock names every SDK the tree is verified with.
pub fn sdk_lock_workflow_drift(fs: &ToolFs, lock: &str) -> List[str]:
    var drift: List[str] = List.new()
    for path in fs.list_files(".github/workflows"):
        if not path.ends_with(".yml"): continue
        let lines = fs.read_text(path).split("\n")
        var pending_asset = ""
        for i in 0..lines.len():
            let line = lines[i]
            let nr = i + 1
            if line.contains("${{"): continue
            for akey in ["sdk_asset:", "WITH_SDK_ASSET:"]:
                let at = line.index_of(akey)
                if at >= 0: pending_asset = line.slice(at + akey.len(), line.len()).trim().to_owned()  // #2307: owned until the seed copies interior views
            for vkey in ["sdk_version:", "WITH_SDK_VERSION:"]:
                let at = line.index_of(vkey)
                if at >= 0:
                    var asset = sdk_lock_block_asset(&lines, i)
                    if asset.len() == 0: asset = pending_asset ++ ""
                    if line.slice(at + vkey.len(), line.len()).trim() != lock_value(lock, asset ++ ".version"):
                        drift.push(f"{path}:{nr}: {line}")
            for dkey in ["sdk_sha256:", "WITH_SDK_SHA256:", "sdk_sidecar_sha256:", "WITH_SDK_SIDECAR_SHA256:", "sdk_manifest_sha256:", "WITH_SDK_MANIFEST_SHA256:"]:
                let at = line.index_of(dkey)
                if at < 0: continue
                var key = pending_asset ++ ""
                if dkey.contains("SIDECAR") or dkey.contains("sidecar"): key = pending_asset ++ ".sha256"
                if dkey.contains("MANIFEST") or dkey.contains("manifest"): key = pending_asset ++ ".manifest"
                if line.slice(at + dkey.len(), line.len()).trim() != lock_value(lock, key):
                    drift.push(f"{path}:{nr}: {line}")
    drift

/// The SDK asset named within the few lines after a release line.
fn sdk_lock_block_asset(lines: &List[str], i: i64) -> str:
    var j = i + 1
    while j < lines.len() and j <= i + 4:
        let line = lines[j]
        for akey in ["sdk_asset:", "WITH_SDK_ASSET:"]:
            let at = line.index_of(akey)
            if at >= 0: return line.slice(at + akey.len(), line.len()).trim().to_owned()
        j = j + 1
    ""
