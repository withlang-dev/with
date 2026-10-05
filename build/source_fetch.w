module build.source_fetch

// Fetching a pinned source archive (#2062). The archive is named by its
// sha256, so where the bytes come from is a list: each source is tried in
// order and the first whose bytes are the pin wins. A source is an https URL,
// or a path in the project (a copy already on disk; the tests use one).
//
// A source that is down must cost seconds. std.net has no connect or receive
// timeout, so the two steps are processes under a deadline:
//   1. build/https_fetch.w --probe opens a TCP connection to the host, under
//      `connect_ms`: a host that does not answer is skipped;
//   2. the download runs under `download_ms`: a host that accepts and then
//      says nothing is skipped when that passes.
// codeberg.org was down on 2026-10-03 and each sysroot build sat in its one
// source's download for the whole 30 minutes it was given.
//
// When no source delivers, the report names the archive, the pin and what
// each source did; the caller fails with it.

use std.build
use std.sysinfo

pub const SOURCE_FETCH_CONNECT_MS: i32 = 20000

pub type SourceFetch {
    rc: i32,
    report: str,
}

fn sf_owned(s: &str): s ++ ""

fn sf_join(left: &str, right: &str) -> str:
    if left.len() == 0: return sf_owned(right)
    if left.ends_with("/"): return left ++ right
    left ++ "/" ++ right

fn sf_is_abs(path: &str) -> bool:
    if path.starts_with("/"): return true
    path.len() > 2 and path[1] == ':'

fn sf_abs(root: &str, path: &str) -> str: if sf_is_abs(path): sf_owned(path) else: sf_join(root, path)

fn sf_basename(path: &str) -> str:
    var last = -1
    for i in 0..path.len() as i32:
        if path[i] == '/' or path[i] == '\\': last = i
    path.slice(last + 1, path.len())

fn sf_exe_suffix() -> str: if os() == "Windows": ".exe" else: ""

// The last line of a helper's output that says anything.
fn sf_last_line(text: &str) -> str:
    var last = ""
    for line in text.split("\n"):
        if line.len() > 0 and line != "\r": last = sf_owned(line)
    last

fn sf_timed_out(result: &ToolProcessResult) -> bool: result.timed_out or result.rc == 124

// Compiles build/https_fetch.w into the scratch directory; its path, or "".
fn sf_helper(ctx: &ActionCtx, scratch: &str, label: &str) -> str:
    let helper = sf_join(scratch, "https_fetch" ++ sf_exe_suffix())
    let workspace = ctx.create_workspace(label ++ "-https-fetch-helper")
    workspace.add_file("build/https_fetch.w")
    var options = workspace.options()
    options.output_path = sf_owned(helper)
    workspace.set_options(options)
    let compiled = workspace.compile()
    if compiled.rc != 0 or not ctx.fs().exists(helper): return ""
    helper

// One https source into `part`: the connection probe under `connect_ms`,
// then the download under `download_ms`. "" when the file was written, else
// why it was not.
fn sf_fetch_https(ctx: &ActionCtx, scratch: &str, helper: &str, label: &str, source: &str, part: &str, connect_ms: i32, download_ms: i32) -> str:
    let root = ctx.project_info().project_root()
    let probe: Vec[str] = Vec.new()
    probe.push(sf_abs(root, helper))
    probe.push("--probe")
    probe.push(sf_owned(source))
    let probed = ctx.process_runner().run_capture(probe, sf_abs(root, sf_join(scratch, label ++ ".probe.stdout")), sf_abs(root, sf_join(scratch, label ++ ".probe.stderr")), connect_ms)
    if sf_timed_out(&probed):
        return f"no connection within {connect_ms / 1000} s"
    if probed.rc != 0:
        let said = sf_last_line(probed.stdout ++ probed.stderr)
        return if said.len() > 0: said else: f"the connection probe failed (exit {probed.rc})"
    let get: Vec[str] = Vec.new()
    get.push(sf_abs(root, helper))
    get.push(sf_owned(source))
    get.push(sf_abs(root, part))
    let got = ctx.process_runner().run_capture(get, sf_abs(root, sf_join(scratch, label ++ ".fetch.stdout")), sf_abs(root, sf_join(scratch, label ++ ".fetch.stderr")), download_ms)
    if sf_timed_out(&got):
        return f"connected, but no complete response within {download_ms / 1000} s"
    if got.rc != 0:
        let said = sf_last_line(got.stdout ++ got.stderr)
        return if said.len() > 0: said else: f"the download failed (exit {got.rc})"
    ""

/// Fetches one https URL to `output` with the same probe and deadlines, for
/// a file that has no pin of its own (a release listing, a digest sidecar).
/// `rc` is 0, or `report` says which URL failed and why.
pub fn source_fetch_url(ctx: &ActionCtx, scratch: &str, label: &str, url: &str, output: &str, connect_ms: i32, download_ms: i32) -> SourceFetch:
    let fs = ctx.fs()
    if fs.mkdir_all(scratch) != 0:
        return SourceFetch { rc: 1, report: "could not create " ++ scratch }
    let helper = sf_helper(ctx, scratch, label)
    if helper.len() == 0:
        return SourceFetch { rc: 1, report: "could not compile build/https_fetch.w" }
    let _stale = fs.remove_file(output)
    let why = sf_fetch_https(ctx, scratch, helper, label, url, output, connect_ms, download_ms)
    if why.len() > 0:
        let _partial = fs.remove_file(output)
        return SourceFetch { rc: 1, report: "could not fetch " ++ url ++ ": " ++ why }
    SourceFetch { rc: 0, report: "  " ++ url ++ ": fetched\n" }

/// Fetches the archive whose sha256 is `sha256` to `output` from the first of
/// `sources` that delivers it. `rc` is 0 and `report` says which source did
/// and what the earlier ones did; otherwise `rc` is nonzero, `output` does
/// not exist and `report` is the failure, naming every source.
pub fn source_fetch_pinned(ctx: &ActionCtx, scratch: &str, label: &str, sources: &Vec[str], sha256: &str, output: &str, connect_ms: i32, download_ms: i32) -> SourceFetch:
    let fs = ctx.fs()
    let root = ctx.project_info().project_root()
    let name = sf_basename(output)
    if sha256.len() != 64:
        return SourceFetch { rc: 1, report: "a source archive is fetched by its pinned sha256; " ++ name ++ " has none" }
    if sources.len() == 0:
        return SourceFetch { rc: 1, report: name ++ " (pinned sha256 " ++ sha256 ++ ") has no source to fetch it from" }
    if fs.mkdir_all(scratch) != 0:
        return SourceFetch { rc: 1, report: "could not create " ++ scratch }
    let helper = sf_helper(ctx, scratch, label)
    if helper.len() == 0:
        return SourceFetch { rc: 1, report: "could not compile build/https_fetch.w" }
    let part = output ++ ".part"
    var tried = ""
    for i in 0..sources.len() as i32:
        let source = sources[i]
        let _stale = fs.remove_file(part)
        var why = ""
        if source.starts_with("https://"):
            why = sf_fetch_https(ctx, scratch, helper, label, source, part, connect_ms, download_ms)
        else if not fs.exists(source):
            why = "no such file"
        else if fs.copy_file(source, part) != 0:
            why = "could not copy it"
        if why.len() == 0:
            let actual = fs.sha256_file(part)
            if actual == sha256:
                if fs.rename(part, output) != 0:
                    return SourceFetch { rc: 1, report: "could not move " ++ part ++ " to " ++ output }
                return SourceFetch { rc: 0, report: tried ++ "  " ++ source ++ ": fetched\n" }
            why = "its sha256 is " ++ actual ++ ", not the pin"
        let _bad = fs.remove_file(part)
        tried = tried ++ "  " ++ source ++ ": " ++ why ++ "\n"
    let count = sources.len() as i32
    let plural = if count == 1: "its source" else: f"any of its {count} sources"
    SourceFetch { rc: 1, report: "could not fetch " ++ name ++ " (pinned sha256 " ++ sha256 ++ ") from " ++ plural ++ ":\n" ++ tried }

// ── `with build :source-fetch-tests` ────────────────────────────────────
// Loopback only: a refused port is a source that is down, a listener that
// never answers is one that accepts and says nothing, and a file in the
// scratch directory is the source that delivers.

fn sft_fail(ctx: &ActionCtx, message: &str) -> i32:
    ctx.diagnostics().error(ctx.target_name() ++ ": " ++ message)

fn sft_expect(ctx: &ActionCtx, case_name: &str, ok: bool, detail: &str) -> i32:
    if ok: return 0
    sft_fail(ctx, case_name ++ ": " ++ detail)

fn sft_digits(text: &str) -> str:
    var end = 0
    while end < text.len() as i32 and text[end] >= '0' and text[end] <= '9':
        end = end + 1
    text.slice(0, end)

pub fn run_source_fetch_tests_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let root = ctx.project_info().project_root()
    let stamp = ctx.output()
    let scratch = sf_join("out/command", ctx.target_name())
    let _clean = fs.remove_tree(scratch)
    if fs.mkdir_all(sf_join(scratch, "got")) != 0:
        return sft_fail(ctx, "could not create " ++ scratch)
    let good = sf_join(scratch, "mirror-archive.bin")
    let other = sf_join(scratch, "other-archive.bin")
    if fs.write_text(good, "the pinned archive\n") != 0 or fs.write_text(other, "some other bytes\n") != 0:
        return sft_fail(ctx, "could not write the fixture archives")
    let pin = fs.sha256_file(good)
    let down_a = "https://127.0.0.1:1/archive.bin"
    let down_b = "https://127.0.0.1:2/archive.bin"

    // 1. The first source is down; the second delivers the pinned bytes.
    let fall: Vec[str] = Vec.new()
    fall.push(sf_owned(down_a))
    fall.push(sf_owned(good))
    let out1 = sf_join(scratch, "got/fallthrough.bin")
    let r1 = source_fetch_pinned(ctx, scratch, "fallthrough", &fall, pin, out1, 5000, 5000)
    var rc = sft_expect(ctx, "fallthrough", r1.rc == 0 and fs.sha256_file(out1) == pin, "the second source was not fetched:\n" ++ r1.report)
    if rc != 0: return rc
    rc = sft_expect(ctx, "fallthrough", r1.report.contains(down_a ++ ": could not connect to 127.0.0.1:1") and r1.report.contains(good ++ ": fetched"), "the report does not say what each source did:\n" ++ r1.report)
    if rc != 0: return rc

    // 2. Every source is down: a failure naming the archive, the pin and
    //    each source, and no output.
    let dead: Vec[str] = Vec.new()
    dead.push(sf_owned(down_a))
    dead.push(sf_owned(down_b))
    let out2 = sf_join(scratch, "got/unreachable.bin")
    let r2 = source_fetch_pinned(ctx, scratch, "unreachable", &dead, pin, out2, 5000, 5000)
    rc = sft_expect(ctx, "unreachable", r2.rc != 0 and not fs.exists(out2) and not fs.exists(out2 ++ ".part"), "a fetch with every source down did not fail cleanly:\n" ++ r2.report)
    if rc != 0: return rc
    rc = sft_expect(ctx, "unreachable", r2.report.contains("could not fetch unreachable.bin (pinned sha256 " ++ pin ++ ") from any of its 2 sources") and r2.report.contains(down_a ++ ": could not connect") and r2.report.contains(down_b ++ ": could not connect"), "the failure does not name the archive, the pin and every source:\n" ++ r2.report)
    if rc != 0: return rc

    // 3. A source that delivers other bytes is not the archive: skipped,
    //    with the digest it had, and the next one is used.
    let wrong: Vec[str] = Vec.new()
    wrong.push(sf_owned(other))
    wrong.push(sf_owned(good))
    let out3 = sf_join(scratch, "got/wrong-bytes.bin")
    let r3 = source_fetch_pinned(ctx, scratch, "wrong-bytes", &wrong, pin, out3, 5000, 5000)
    rc = sft_expect(ctx, "wrong-bytes", r3.rc == 0 and fs.sha256_file(out3) == pin and r3.report.contains(other ++ ": its sha256 is " ++ fs.sha256_file(other) ++ ", not the pin"), "a source with other bytes was not skipped for the next:\n" ++ r3.report)
    if rc != 0: return rc

    // 4. A source that accepts the connection and never answers: the
    //    download's deadline ends it and the next source is used. Without
    //    the deadline this case never returns.
    let listener = sf_join(scratch, "silent_listener" ++ sf_exe_suffix())
    let workspace = ctx.create_workspace("source-fetch-tests-silent-listener")
    workspace.add_file("build/silent_listener.w")
    var options = workspace.options()
    options.output_path = sf_owned(listener)
    workspace.set_options(options)
    let compiled = workspace.compile()
    if compiled.rc != 0 or not fs.exists(listener):
        return sft_fail(ctx, f"could not compile build/silent_listener.w (exit {compiled.rc})")
    let port_file = sf_join(scratch, "silent.port")
    let serve: Vec[str] = Vec.new()
    serve.push(sf_abs(root, listener))
    serve.push(sf_abs(root, port_file))
    let pid = ctx.process_runner().spawn_capture(serve, sf_abs(root, sf_join(scratch, "silent.stdout")), sf_abs(root, sf_join(scratch, "silent.stderr")))
    if pid <= 0:
        return sft_fail(ctx, "could not start the silent listener")
    var port = ""
    var waited = 0
    while port.len() == 0 and waited < 15:
        if fs.exists(port_file): port = sft_digits(fs.read_text(port_file))
        if port.len() == 0:
            let nap: Vec[str] = Vec.new()
            nap.push(sf_abs(root, listener))
            nap.push("nap")
            let _napped = ctx.process_runner().run_capture(nap, sf_abs(root, sf_join(scratch, "nap.stdout")), sf_abs(root, sf_join(scratch, "nap.stderr")), 10000)
            waited = waited + 1
    if port.len() == 0:
        let _reaped = ctx.process_runner().wait(pid, 30000)
        return sft_fail(ctx, "the silent listener never wrote its port to " ++ port_file)
    let silent = "https://127.0.0.1:" ++ port ++ "/archive.bin"
    let stall: Vec[str] = Vec.new()
    stall.push(sf_owned(silent))
    stall.push(sf_owned(good))
    let out4 = sf_join(scratch, "got/stalled.bin")
    let r4 = source_fetch_pinned(ctx, scratch, "stalled", &stall, pin, out4, 5000, 3000)
    let _reaped = ctx.process_runner().wait(pid, 30000)
    rc = sft_expect(ctx, "stalled", r4.rc == 0 and fs.sha256_file(out4) == pin and r4.report.contains(silent ++ ": connected, but no complete response within 3 s"), "a source that never answers was not abandoned at its deadline for the next:\n" ++ r4.report)
    if rc != 0: return rc

    // 5. No pin, no fetch.
    let r5 = source_fetch_pinned(ctx, scratch, "unpinned", &fall, "", sf_join(scratch, "got/unpinned.bin"), 5000, 5000)
    rc = sft_expect(ctx, "unpinned", r5.rc != 0 and not fs.exists(sf_join(scratch, "got/unpinned.bin")), "an archive with no pin was fetched")
    if rc != 0: return rc

    if fs.write_text(stamp, "fallthrough, unreachable, wrong-bytes, stalled, unpinned: ok\n") != 0:
        return sft_fail(ctx, "could not write " ++ stamp)
    0

// ── `with build :source-cache-tests` ────────────────────────────────────
// std.build's ActionCtx.fetch_source and the machine-wide source cache
// (#2062), driven by the fresh release compiler: each case is a project of
// its own (a worktree, as far as the cache can tell) whose build.w fetches
// one pinned archive, and all of them share one build cache directory.

fn sct_build_w(pin: &str, source: &str) -> str:
    "use std.build\n\n" ++
    "fn fetch(ctx: ActionCtx) -> i32:\n" ++
    "    let sources: Vec[str] = Vec.new()\n" ++
    "    sources.push(ctx.args()[1] ++ \"\")\n" ++
    "    let got = ctx.fetch_source(&sources, ctx.args()[0], ctx.output(), 20000)\n" ++
    "    let how = if got.rc != 0: \"failed\" else if got.from_cache: \"cache\" else: \"fetched\"\n" ++
    "    let _ = ctx.fs().write_text(\"out/fetch/report.txt\", how ++ \"\\n\" ++ got.report)\n" ++
    "    if got.rc != 0:\n" ++
    "        ctx.diagnostics().error(ctx.target_name() ++ \": \" ++ got.report)\n" ++
    "    0\n\n" ++
    "pub fn build(ctx: BuildCtx) -> Build:\n" ++
    "    var out = ctx.new_build()\n" ++
    "    var target = target_new(.Action, \"fetch\", \"\").output(\"out/fetch/archive.bin\")\n" ++
    "    target.action = fetch\n" ++
    "    target = target.arg(\"" ++ pin ++ "\").arg(\"" ++ source ++ "\")\n" ++
    "    target = target.write_scope(\"out/fetch\").write_scope(\"out/command/fetch\")\n" ++
    "    target = target.allow_network()\n" ++
    "    out = out.add_target(target)\n" ++
    "    out.default(\"fetch\")\n"

// Writes the case's project and runs `<compiler> build` in it with the
// shared cache directory (or "none"). The child's result.
fn sct_run(ctx: &ActionCtx, compiler: &str, scratch: &str, case_name: &str, pin: &str, source: &str, cache: &str) -> ToolProcessResult:
    let fs = ctx.fs()
    let root = ctx.project_info().project_root()
    let dir = sf_join(scratch, case_name)
    let wrote = fs.mkdir_all(dir) == 0 and fs.write_text(sf_join(dir, "with.toml"), "[package]\nname = \"" ++ case_name.replace("-", "") ++ "\"\nversion = \"0.1.0\"\n") == 0 and fs.write_text(sf_join(dir, "build.w"), sct_build_w(pin, source)) == 0 and fs.write_text(sf_join(dir, "archive-src.bin"), "the pinned archive\n") == 0
    if not wrote:
        return ToolProcessResult { rc: -1, stdout: "", stderr: "could not write the project in " ++ dir, timed_out: false }
    let argv: Vec[str] = Vec.new()
    argv.push(sf_abs(root, compiler))
    argv.push("build")
    var env = process_env()
    env = env.set("WITH_BUILD_CACHE_DIR", if cache == "none": "none" else: sf_abs(root, cache))
    env = env.set("WITH", sf_abs(root, compiler))
    ctx.process_runner().run_capture_cwd_with_env(argv, sf_abs(root, sf_join(scratch, case_name ++ ".stdout")), sf_abs(root, sf_join(scratch, case_name ++ ".stderr")), 300000, sf_abs(root, dir), env)

pub fn run_source_cache_tests_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let inputs = ctx.inputs()
    let stamp = ctx.output()
    if inputs.len() == 0:
        return sft_fail(ctx, "requires the release compiler as its first input")
    let compiler = inputs[0]
    let scratch = sf_join("out/command", ctx.target_name())
    let _clean = fs.remove_tree(scratch)
    if fs.mkdir_all(scratch) != 0:
        return sft_fail(ctx, "could not create " ++ scratch)
    let pin_file = sf_join(scratch, "pin-source.bin")
    if fs.write_text(pin_file, "the pinned archive\n") != 0:
        return sft_fail(ctx, "could not write " ++ pin_file)
    let pin = fs.sha256_file(pin_file)
    let cache = sf_join(scratch, "cache")
    let entry = sf_join(cache, "sources/" ++ pin)
    let down = "https://127.0.0.1:1/archive.bin"

    // 1. The first worktree fetches (from a file beside it) and the bytes
    //    land in the machine's source cache under their digest.
    let r1 = sct_run(ctx, compiler, scratch, "first-worktree", pin, "archive-src.bin", cache)
    let report1 = fs.read_text(sf_join(scratch, "first-worktree/out/fetch/report.txt"))
    var rc = sft_expect(ctx, "first-worktree", r1.rc == 0 and report1.starts_with("fetched\n") and fs.sha256_file(sf_join(scratch, "first-worktree/out/fetch/archive.bin")) == pin, f"the first fetch did not deliver the archive (exit {r1.rc}):\n" ++ report1 ++ r1.stdout ++ r1.stderr)
    if rc != 0: return rc
    rc = sft_expect(ctx, "first-worktree", fs.sha256_file(entry) == pin, "the fetched archive is not in the source cache at " ++ entry)
    if rc != 0: return rc

    // 2. A second worktree whose only source is down gets the archive from
    //    the cache: it fetches nothing, and does not even build the fetch
    //    program.
    let r2 = sct_run(ctx, compiler, scratch, "second-worktree", pin, down, cache)
    let report2 = fs.read_text(sf_join(scratch, "second-worktree/out/fetch/report.txt"))
    rc = sft_expect(ctx, "second-worktree", r2.rc == 0 and report2.starts_with("cache\n") and fs.sha256_file(sf_join(scratch, "second-worktree/out/fetch/archive.bin")) == pin, f"a second worktree was not served from the source cache (exit {r2.rc}):\n" ++ report2 ++ r2.stdout ++ r2.stderr)
    if rc != 0: return rc
    rc = sft_expect(ctx, "second-worktree", not fs.exists(sf_join(scratch, "second-worktree/out/command/fetch/https_fetch")) and not fs.exists(sf_join(scratch, "second-worktree/out/command/fetch/https_fetch.exe")) and not fs.exists(sf_join(scratch, "second-worktree/out/command/fetch/https_fetch.stdout")), "a second worktree built or ran the fetch program although the archive was cached")
    if rc != 0: return rc

    // 3. With no cache, the same down source fails, soon, naming the
    //    archive, the pin and the source.
    let r3 = sct_run(ctx, compiler, scratch, "no-cache", pin, down, "none")
    rc = sft_expect(ctx, "no-cache", r3.rc != 0 and not r3.timed_out and not fs.exists(sf_join(scratch, "no-cache/out/fetch/archive.bin")), f"a fetch with its source down and no cache did not fail (exit {r3.rc})")
    if rc != 0: return rc
    let said3 = r3.stdout ++ r3.stderr
    rc = sft_expect(ctx, "no-cache", said3.contains("could not fetch archive.bin (pinned sha256 " ++ pin ++ ") from its source") and said3.contains(down ++ ": no connection to 127.0.0.1:1"), "the failure does not name the archive, the pin and the source:\n" ++ said3)
    if rc != 0: return rc

    // 4. A cache entry that is not the pinned bytes is never served: it is
    //    dropped, the archive is fetched, and the entry is the pin again.
    if fs.write_text(entry, "not the pinned archive\n") != 0:
        return sft_fail(ctx, "could not corrupt " ++ entry)
    // (Named differently from the first worktree's source: with the same
    // inputs the build store would restore the action's output and the
    // fetch would not run at all.)
    let r4 = sct_run(ctx, compiler, scratch, "corrupt-cache", pin, "./archive-src.bin", cache)
    let report4 = fs.read_text(sf_join(scratch, "corrupt-cache/out/fetch/report.txt"))
    rc = sft_expect(ctx, "corrupt-cache", r4.rc == 0 and report4.starts_with("fetched\n") and fs.sha256_file(sf_join(scratch, "corrupt-cache/out/fetch/archive.bin")) == pin and fs.sha256_file(entry) == pin, f"a corrupt cache entry was served or left in place (exit {r4.rc}):\n" ++ report4 ++ r4.stdout ++ r4.stderr)
    if rc != 0: return rc

    if fs.write_text(stamp, "first-worktree, second-worktree, no-cache, corrupt-cache: ok\n") != 0:
        return sft_fail(ctx, "could not write " ++ stamp)
    0
