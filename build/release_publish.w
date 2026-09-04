module build.release_publish

// `with build :publish-release-asset` — publish ONE platform's verified
// asset to a GitHub release, add-only, from wherever it was built.
//
// A release is created by whoever finishes first (a CI platform job, or the
// maintainer's laptop with a fixpoint-verified darwin binary — the fast lane)
// and every platform adds its own asset when it is done; nobody waits for
// the slowest runner (Eric, 2026-09-04: "It will not do for me to wait 3
// hours every time I publish"). Three rules keep that honest:
//
// - assets are add-only: an asset name already on the release is a hard
//   failure, never a replacement;
// - provenance travels with the asset: `<asset>.provenance` names the
//   commit, the builder (workflow run or host), the fixpoint verdict and the
//   time, and the release notes are regenerated from the sidecars present;
// - consumers cope: `with build :seed` and the seed pins select by asset and
//   digest, so a release that is darwin-only for an hour is invisible to a
//   Linux user and harmless to CI.
//
// Environment (the workflow and the runbook both set it):
//   RELEASE_TAG        the tag (created if absent, at RELEASE_SOURCE_SHA)
//   RELEASE_TITLE      release title (used only when creating)
//   RELEASE_CHANNEL    release | nightly | test (anything but release is a
//                      prerelease; a stable tag never becomes one)
//   RELEASE_ASSETS     comma-separated asset paths; each `<asset>.sha256`
//                      sidecar must exist and verify
//   RELEASE_EXTRA_FILES comma-separated files uploaded as they are, add-only
//                      (the already-verified SDK archive and its sidecars)
//   RELEASE_SOURCE_SHA the source commit (GITHUB_SHA on CI; git HEAD here)
//   RELEASE_BUILDER    who built it, e.g. a workflow run URL or a hostname
//   RELEASE_REPO       owner/name (default withlang-dev/with)
//   GH_TOKEN           a token gh can publish with
use std.build
use std.process

fn rp_join(left: &str, right: &str) -> str:
    if left.len() == 0: return right ++ ""
    if left.ends_with("/"): return left ++ right
    left ++ "/" ++ right

fn rp_basename(path: &str) -> str:
    var last_slash: i64 = -1
    for i in 0..path.len():
        if path[i] == '/': last_slash = i
    path.slice(last_slash + 1, path.len())

fn rp_fail(ctx: &ActionCtx, message: &str) -> i32:
    ctx.diagnostics().error(ctx.target_name() ++ ": " ++ message)
    1

fn rp_split_commas(text: &str) -> Vec[str]:
    var out: Vec[str] = Vec.new()
    for part in text.split(","):
        let p = part.trim()
        if p.len() > 0: out.push(p ++ "")
    out

/// `gh release <sub> <tag> --repo <repo> <rest...>` as an argv (owned copies:
/// an array literal would move its str elements).
fn rp_release_args(sub: &str, tag: &str, repo: &str, rest: &Vec[str]) -> Vec[str]:
    var out: Vec[str] = Vec.new()
    out.push("release")
    out.push(sub ++ "")
    out.push(tag ++ "")
    out.push("--repo")
    out.push(repo ++ "")
    for r in rest: out.push(r ++ "")
    out

/// `gh <args...>` captured; the result carries rc, stdout and stderr.
fn rp_gh(ctx: &ActionCtx, scratch: &str, label: &str, args: &Vec[str]) -> ToolProcessResult:
    let root = ctx.project_info().project_root()
    var argv: Vec[str] = Vec.new()
    argv.push("gh")
    for a in args: argv.push(a ++ "")
    let out_path = rp_join(scratch, label ++ ".stdout")
    let err_path = rp_join(scratch, label ++ ".stderr")
    ctx.process_runner().run_capture(argv, rp_join(root, out_path), rp_join(root, err_path), 600000)

fn rp_trim_lines(text: &str) -> Vec[str]:
    var out: Vec[str] = Vec.new()
    for line in text.split("\n"):
        let l = line.trim()
        if l.len() > 0: out.push(l ++ "")
    out

/// The digest recorded in `<asset>.sha256` (first field), or "".
fn rp_sidecar_digest(fs: &ToolFs, asset: &str) -> str:
    let text = fs.read_text(asset ++ ".sha256").trim()
    let sp = text.index_of(" ")
    let digest = if sp > 0: text.slice(0, sp) else: text
    if digest.len() == 64: digest ++ "" else: ""

/// The release notes: what a reader needs to trust each asset, regenerated
/// from the provenance sidecars present on the release after every upload.
fn rp_notes(channel: &str, version: &str, source_sha: &str, rows: &Vec[str]) -> str:
    let publication = if channel == "release": "release" else: "prerelease"
    let automation = if channel == "release": "Automated compiler " else: "Automated " ++ channel ++ " compiler "
    var notes = automation ++ publication ++ ".\n\n" ++
        "Source commit: " ++ source_sha ++ "\n" ++
        "Compiler version: " ++ version ++ "\n\n" ++
        "Assets are published per platform as each finishes its fixpoint-verified build; " ++
        "an asset is never replaced once published. Each binary has a SHA-256 sidecar and a " ++
        "`.provenance` sidecar naming its commit, builder and time.\n\n" ++
        "| asset | built by | at |\n|---|---|---|\n"
    for row in rows: notes = notes ++ row ++ "\n"
    notes ++ "\nVerification gates on each platform:\n\n" ++
        "- `WITH_VERSION=" ++ version ++ " with build`\n" ++
        "- `WITH_VERSION=" ++ version ++ " with build :fixpoint`\n" ++
        "- Fixpoint-verified `out/release/bin/with` copied to the platform asset with a SHA-256 sidecar\n"

/// One `key=value` line of a provenance sidecar.
fn rp_field(text: &str, key: &str) -> str:
    for line in text.split("\n"):
        let eq = line.index_of("=")
        if eq > 0 and line.slice(0, eq) == key: return line.slice(eq + 1, line.len()).trim()
    ""

pub fn run_publish_release_asset_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let root = ctx.project_info().project_root()
    let tag = env("RELEASE_TAG")
    let title = env("RELEASE_TITLE")
    let channel = env("RELEASE_CHANNEL")
    let assets = rp_split_commas(env("RELEASE_ASSETS"))
    let extras = rp_split_commas(env("RELEASE_EXTRA_FILES"))
    var source_sha = env("RELEASE_SOURCE_SHA")
    let builder = env("RELEASE_BUILDER")
    var repo = env("RELEASE_REPO")
    if repo.len() == 0: repo = "withlang-dev/with"
    if tag.len() == 0 or title.len() == 0 or assets.len() == 0:
        return rp_fail(&ctx, "RELEASE_TAG, RELEASE_TITLE and RELEASE_ASSETS are required")
    if channel != "release" and channel != "nightly" and channel != "test":
        return rp_fail(&ctx, "RELEASE_CHANNEL must be release, nightly or test (got '" ++ channel ++ "')")
    if env("GH_TOKEN").len() == 0 and env("GITHUB_TOKEN").len() == 0:
        return rp_fail(&ctx, "GH_TOKEN is not set; gh cannot publish")
    let scratch = "out/tmp/publish-release-asset"
    if fs.mkdir_all(scratch) != 0:
        return rp_fail(&ctx, "could not create " ++ scratch)

    if source_sha.len() == 0:
        var argv: Vec[str] = Vec.new()
        argv.push("git")
        argv.push("rev-parse")
        argv.push("HEAD")
        let head = ctx.process_runner().run_capture(argv, rp_join(root, rp_join(scratch, "head.stdout")), rp_join(root, rp_join(scratch, "head.stderr")), 60000)
        if head.rc != 0: return rp_fail(&ctx, "RELEASE_SOURCE_SHA is not set and `git rev-parse HEAD` failed")
        source_sha = head.stdout.trim()
    if source_sha.len() < 12:
        return rp_fail(&ctx, "the source commit must have at least 12 hex characters: '" ++ source_sha ++ "'")
    // A release can only point at a commit the repository has; a local
    // build of an unpushed commit says so instead of a 422 from the API.
    var commit_args: Vec[str] = Vec.new()
    commit_args.push("api")
    commit_args.push("repos/" ++ repo ++ "/commits/" ++ source_sha)
    commit_args.push("--jq")
    commit_args.push(".sha")
    let commit = rp_gh(&ctx, scratch, "commit", &commit_args)
    if commit.rc != 0:
        return rp_fail(&ctx, "source commit " ++ source_sha ++ " is not on " ++ repo ++ " (push it, or set RELEASE_SOURCE_SHA to a pushed commit)")

    // Every asset and its digest sidecar exist and agree before anything is
    // published; a half-published platform is worse than none.
    for asset in assets:
        if not fs.exists(asset): return rp_fail(&ctx, "missing asset " ++ asset)
        let recorded = rp_sidecar_digest(fs, asset)
        if recorded.len() == 0: return rp_fail(&ctx, "missing or malformed " ++ asset ++ ".sha256")
        let actual = fs.sha256_file(asset)
        if actual != recorded:
            return rp_fail(&ctx, asset ++ ": sidecar digest " ++ recorded ++ " does not match the file's " ++ actual)
    for extra in extras:
        if not fs.exists(extra): return rp_fail(&ctx, "missing extra file " ++ extra)

    // The release: created by whoever gets here first. A stable channel
    // publishes at an existing `v*` tag; the other channels create the tag
    // at the source commit. Two platforms racing to create it: the loser
    // sees "already exists" and carries on with the upload.
    var view_rest: Vec[str] = Vec.new()
    view_rest.push("--json")
    view_rest.push("isPrerelease,targetCommitish")
    let view_args = rp_release_args("view", tag, repo, &view_rest)
    var view = rp_gh(&ctx, scratch, "view", &view_args)
    if view.rc != 0:
        let notes_path = rp_join(scratch, "notes.md")
        let no_rows: Vec[str] = Vec.new()
        let _ = fs.write_text(notes_path, rp_notes(channel, tag, source_sha, &no_rows))
        var create_rest: Vec[str] = Vec.new()
        create_rest.push("--target")
        create_rest.push(source_sha ++ "")
        create_rest.push("--title")
        create_rest.push(title ++ "")
        create_rest.push("--notes-file")
        create_rest.push(notes_path ++ "")
        if channel != "release": create_rest.push("--prerelease")
        let create = rp_release_args("create", tag, repo, &create_rest)
        print("publish: creating release " ++ tag ++ " (" ++ channel ++ ") at " ++ source_sha)
        let created = rp_gh(&ctx, scratch, "create", &create)
        view = rp_gh(&ctx, scratch, "view", &view_args)
        if view.rc != 0:
            return rp_fail(&ctx, "could not create or find release " ++ tag ++ ": " ++ created.stderr)
    let is_prerelease = view.stdout.contains("\"isPrerelease\":true")
    if channel == "release" and is_prerelease:
        return rp_fail(&ctx, tag ++ " is a prerelease but the channel is release")
    if channel != "release" and not is_prerelease:
        return rp_fail(&ctx, tag ++ " is a stable release; a " ++ channel ++ " build cannot publish into it")

    // Add-only: the names already on the release are off limits.
    var names_rest: Vec[str] = Vec.new()
    names_rest.push("--json")
    names_rest.push("assets")
    names_rest.push("--jq")
    names_rest.push(".assets[].name")
    let names_args = rp_release_args("view", tag, repo, &names_rest)
    let names = rp_gh(&ctx, scratch, "names", &names_args)
    if names.rc != 0: return rp_fail(&ctx, "could not list the assets of " ++ tag ++ ": " ++ names.stderr)
    let present = rp_trim_lines(names.stdout)
    for asset in assets:
        let name = rp_basename(asset)
        for p in present:
            if p == name:
                return rp_fail(&ctx, name ++ " is already published on " ++ tag ++ "; assets are add-only (a different build needs a different tag)")
    // Extra files (the SDK archive and sidecars) are shared between the
    // platforms that reuse the same SDK; one already present is skipped,
    // never replaced.
    var extras_to_upload: Vec[str] = Vec.new()
    for extra in extras:
        let name = rp_basename(extra)
        var already = false
        for p in present:
            if p == name: already = true
        if not already: extras_to_upload.push(extra ++ "")

    // Provenance sidecars, then one upload of everything.
    let no_rest: Vec[str] = Vec.new()
    var upload = rp_release_args("upload", tag, repo, &no_rest)
    var date_args: Vec[str] = Vec.new()
    date_args.push("date")
    date_args.push("-u")
    date_args.push("+%Y-%m-%dT%H:%M:%SZ")
    let when = ctx.process_runner().run_capture(date_args, rp_join(root, rp_join(scratch, "date.stdout")), rp_join(root, rp_join(scratch, "date.stderr")), 60000)
    let built_at = if when.rc == 0: when.stdout.trim() else: "unknown"
    for asset in assets:
        let name = rp_basename(asset)
        let provenance = asset ++ ".provenance"
        let text = "asset=" ++ name ++ "\n" ++
            "sha256=" ++ rp_sidecar_digest(fs, asset) ++ "\n" ++
            "source_sha=" ++ source_sha ++ "\n" ++
            "version=" ++ tag ++ "\n" ++
            "channel=" ++ channel ++ "\n" ++
            "builder=" ++ (if builder.len() > 0: builder else: "unknown") ++ "\n" ++
            "fixpoint=verified\n" ++
            "built_at=" ++ built_at ++ "\n"
        if fs.write_text(provenance, text) != 0: return rp_fail(&ctx, "could not write " ++ provenance)
        upload.push(asset ++ "")
        upload.push(asset ++ ".sha256")
        upload.push(provenance)
    for extra in extras_to_upload: upload.push(extra ++ "")
    print(f"publish: uploading {assets.len()} asset(s) and {extras_to_upload.len()} extra file(s) to {tag}")
    let uploaded = rp_gh(&ctx, scratch, "upload", &upload)
    if uploaded.rc != 0: return rp_fail(&ctx, "upload to " ++ tag ++ " failed: " ++ uploaded.stderr)

    // The published digest is the file's digest.
    for asset in assets:
        let name = rp_basename(asset)
        let digest_query = ".assets[] | select(.name == \"" ++ name ++ "\") | .digest"
        var digest_rest: Vec[str] = Vec.new()
        digest_rest.push("--json")
        digest_rest.push("assets")
        digest_rest.push("--jq")
        digest_rest.push(digest_query ++ "")
        let digest_args = rp_release_args("view", tag, repo, &digest_rest)
        let published = rp_gh(&ctx, scratch, "digest", &digest_args)
        if published.rc != 0 or published.stdout.trim() != "sha256:" ++ rp_sidecar_digest(fs, asset):
            return rp_fail(&ctx, name ++ ": published digest '" ++ published.stdout.trim() ++ "' does not match the sidecar")

    // Notes: regenerated from every provenance sidecar now on the release.
    var prov_rest: Vec[str] = Vec.new()
    prov_rest.push("--json")
    prov_rest.push("assets")
    prov_rest.push("--jq")
    prov_rest.push(".assets[] | select(.name | endswith(\".provenance\")) | .name")
    let prov_args = rp_release_args("view", tag, repo, &prov_rest)
    let prov_names = rp_gh(&ctx, scratch, "provenance-names", &prov_args)
    var rows: Vec[str] = Vec.new()
    if prov_names.rc == 0:
        let prov_dir = rp_join(scratch, "provenance")
        let _rm = fs.remove_tree(prov_dir)
        let _mk = fs.mkdir_all(prov_dir)
        for pname in rp_trim_lines(prov_names.stdout):
            var dl_rest: Vec[str] = Vec.new()
            dl_rest.push("--pattern")
            dl_rest.push(pname ++ "")
            dl_rest.push("--dir")
            dl_rest.push(prov_dir ++ "")
            dl_rest.push("--clobber")
            let dl = rp_release_args("download", tag, repo, &dl_rest)
            let got = rp_gh(&ctx, scratch, "provenance-dl", &dl)
            let path = rp_join(prov_dir, pname)
            if got.rc != 0 or not fs.exists(path): continue
            let text = fs.read_text(path)
            rows.push("| " ++ rp_field(text, "asset") ++ " | " ++ rp_field(text, "builder") ++ " | " ++ rp_field(text, "built_at") ++ " |")
    let notes_path = rp_join(scratch, "notes.md")
    if fs.write_text(notes_path, rp_notes(channel, tag, source_sha, &rows)) != 0:
        return rp_fail(&ctx, "could not write " ++ notes_path)
    var edit_rest: Vec[str] = Vec.new()
    edit_rest.push("--notes-file")
    edit_rest.push(notes_path ++ "")
    let edit = rp_release_args("edit", tag, repo, &edit_rest)
    let edited = rp_gh(&ctx, scratch, "edit", &edit)
    if edited.rc != 0: return rp_fail(&ctx, "could not update the notes of " ++ tag ++ ": " ++ edited.stderr)
    print(f"publish: {tag} now carries {rows.len()} asset(s)")
    let output_dir = ctx.output()
    if output_dir.len() > 0:
        let _ = fs.mkdir_all(output_dir)
        let _ = fs.write_text(rp_join(output_dir, ".stamp"), tag ++ "\n")
    0
