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
    let helper = sf_join(scratch, "https_fetch" ++ sf_exe_suffix())
    let workspace = ctx.create_workspace(label ++ "-https-fetch-helper")
    workspace.add_file("build/https_fetch.w")
    var options = workspace.options()
    options.output_path = sf_owned(helper)
    workspace.set_options(options)
    let compiled = workspace.compile()
    if compiled.rc != 0 or not fs.exists(helper):
        return SourceFetch { rc: 1, report: f"could not compile build/https_fetch.w (exit {compiled.rc})" }
    let part = output ++ ".part"
    let connect_s = connect_ms / 1000
    let download_s = download_ms / 1000
    var tried = ""
    for i in 0..sources.len() as i32:
        let source = sources[i]
        let _stale = fs.remove_file(part)
        var why = ""
        if source.starts_with("https://"):
            let probe: Vec[str] = Vec.new()
            probe.push(sf_abs(root, helper))
            probe.push("--probe")
            probe.push(sf_owned(source))
            let probed = ctx.process_runner().run_capture(probe, sf_abs(root, sf_join(scratch, label ++ ".probe.stdout")), sf_abs(root, sf_join(scratch, label ++ ".probe.stderr")), connect_ms)
            if sf_timed_out(&probed):
                why = f"no connection within {connect_s} s"
            else if probed.rc != 0:
                why = sf_last_line(probed.stdout ++ probed.stderr)
                if why.len() == 0: why = f"the connection probe failed (exit {probed.rc})"
            else:
                let get: Vec[str] = Vec.new()
                get.push(sf_abs(root, helper))
                get.push(sf_owned(source))
                get.push(sf_abs(root, part))
                let got = ctx.process_runner().run_capture(get, sf_abs(root, sf_join(scratch, label ++ ".fetch.stdout")), sf_abs(root, sf_join(scratch, label ++ ".fetch.stderr")), download_ms)
                if sf_timed_out(&got):
                    why = f"connected, but no complete response within {download_s} s"
                else if got.rc != 0:
                    why = sf_last_line(got.stdout ++ got.stderr)
                    if why.len() == 0: why = f"the download failed (exit {got.rc})"
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
