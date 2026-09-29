module build.host_toolchain

// `with build :no-host-toolchain` (#1915): the build reads nothing but our
// SDK (.deps, or the LLVM_PREFIX a lane pins), this repository and out/ —
// never Xcode, the Command Line Tools, an Apple SDK, Visual Studio or a
// system gcc (Eric, 2026-09-29: "zero dependencies in all platforms ...
// except our own SDK and system calls"). A new external dependency turns
// this check red instead of arriving silently.
//
// Two halves:
//   1. every link response file and linker record the build wrote names only
//      paths under the repository or the SDK;
//   2. the fresh release compiler builds and runs test/host_toolchain/*.w
//      with an empty environment (PATH=/nonexistent, a fresh HOME) inside a
//      sandbox that denies reading /Library/Developer and
//      /Applications/Xcode.app and running the host's cc, ld, nm or xcrun,
//      and each program prints its `//! expect-stdout:` lines.
// The sandbox half is macOS's (sandbox-exec is part of the OS); the Linux and
// Windows slices of #1915 add theirs.

use std.build
use std.sysinfo
use build.compiler

fn ht_fail(ctx: &ActionCtx, message: &str) -> i32:
    ctx.diagnostics().error("no-host-toolchain: " ++ message)

fn ht_join(a: &str, b: &str) -> str:
    if a.len() == 0: b.to_owned() else if a.ends_with("/"): a ++ b else: a ++ "/" ++ b

// Paths no build input may name.
fn ht_forbidden_markers() -> Vec[str]:
    let out: Vec[str] = Vec.new()
    out.push("/Library/Developer")
    out.push("/Applications/Xcode")
    out.push("MacOSX.sdk")
    out.push("/usr/lib/gcc")
    out.push("/usr/lib/x86_64-linux-gnu")
    out.push("/usr/lib/aarch64-linux-gnu")
    out.push("Program Files")
    out.push("Windows Kits")
    out

// The link records the build writes for the compiler's own links.
fn ht_link_records() -> Vec[str]:
    let out: Vec[str] = Vec.new()
    let dirs: Vec[str] = Vec.new()
    dirs.push("out/bootstrap-lib")
    dirs.push("out/bootstrap/lib")
    dirs.push("out/lib")
    let names: Vec[str] = Vec.new()
    names.push("llvm_ld.rsp")
    names.push("llvm_link.rsp")
    names.push("llvm_ld")
    names.push("llvm_cc")
    for d in 0..dirs.len() as i32:
        for n in 0..names.len() as i32:
            out.push(dirs[d] ++ "/" ++ names[n])
    out

// Indexing and slice only: the pinned seed evaluates this action at comptime,
// where str.trim is not available.
fn ht_trim(s: &str) -> str:
    var start = 0
    var end = s.len() as i32
    while start < end and (s[start] == ' ' or s[start] == '\t' or s[start] == '\r'):
        start = start + 1
    while end > start and (s[end - 1] == ' ' or s[end - 1] == '\t' or s[end - 1] == '\r'):
        end = end - 1
    s.slice(start, end)

// One response-file token per line; a quoted one keeps its spaces.
fn ht_unquote(token: &str) -> str:
    if token.len() >= 2 and token.starts_with("\"") and token.ends_with("\""):
        return token.slice(1, token.len() - 1)
    token.to_owned()

// Every problem with one record: a forbidden marker, or an absolute path
// outside the repository and the SDK.
fn ht_record_problems(path: &str, text: &str, root: &str, sdk: &str) -> Vec[str]:
    let problems: Vec[str] = Vec.new()
    let markers = ht_forbidden_markers()
    for line in text.split("\n"):
        let token = ht_unquote(ht_trim(line))
        if token.len() == 0:
            continue
        var flagged = false
        for m in 0..markers.len() as i32:
            if not flagged and token.find(markers[m]) >= 0:
                problems.push(path ++ ": names the host toolchain (" ++ markers[m] ++ "): " ++ token)
                flagged = true
        // `-Wl,-foo,/path` and `-L/path` carry a path after a prefix too.
        let at = token.find("/")
        if not flagged and at >= 0:
            let candidate = token.slice(at, token.len())
            let prefix = token.slice(0, at)
            let path_like = at == 0 or prefix.ends_with(",") or prefix.ends_with("=") or prefix == "-L" or prefix == "-F" or prefix == "-I" or prefix == "@"
            if path_like and not candidate.starts_with(root) and not (sdk.len() > 0 and candidate.starts_with(sdk)) and candidate != "/dev/null":
                problems.push(path ++ ": names a path outside the repository and the SDK: " ++ token)
    problems

// The `//! expect-stdout:` lines of a fixture, in order.
fn ht_expected_stdout(text: &str) -> str:
    var out = ""
    let marker = "//! expect-stdout: "
    for line in text.split("\n"):
        if line.starts_with(marker):
            out = out ++ line.slice(marker.len(), line.len()) ++ "\n"
    out

// The sandbox: everything allowed but reading the host's developer tools,
// and running the host's compiler driver, linker, nm or xcrun.
fn ht_sandbox_profile() -> str:
    var p = "(version 1)(allow default)"
    p = p ++ "(deny file-read* (subpath \"/Library/Developer\") (subpath \"/Applications/Xcode.app\"))"
    p = p ++ "(deny process-exec (literal \"/usr/bin/cc\") (literal \"/usr/bin/clang\") (literal \"/usr/bin/ld\") (literal \"/usr/bin/nm\") (literal \"/usr/bin/xcrun\") (literal \"/usr/bin/dsymutil\"))"
    p

fn ht_sandboxed(profile: &str, home: &str, command: Vec[str]) -> Vec[str]:
    let argv: Vec[str] = Vec.new()
    argv.push("/usr/bin/sandbox-exec")
    argv.push("-p")
    argv.push(profile.to_owned())
    argv.push("/usr/bin/env")
    argv.push("-i")
    argv.push("HOME=" ++ home)
    argv.push("PATH=/nonexistent")
    argv.push("TMPDIR=" ++ home ++ "/tmp")
    for i in 0..command.len() as i32:
        argv.push(command[i].clone())
    argv

pub fn run_no_host_toolchain_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let root = ctx.project_info().project_root()
    let output = ctx.output()
    let inputs = ctx.inputs()
    if output.len() == 0 or inputs.len() == 0:
        return ht_fail(ctx, "requires the release compiler input and an output path")
    // An SDK named by LLVM_PREFIX (a lane's pinned SDK) is ours too.
    let sdk = ctx.env_input("LLVM_PREFIX")
    var problems: Vec[str] = Vec.new()
    let records = ht_link_records()
    var read = 0
    for r in 0..records.len() as i32:
        if not fs.exists(records[r]):
            continue
        read = read + 1
        let found = ht_record_problems(records[r], fs.read_text(records[r]), root, sdk)
        for f in 0..found.len() as i32:
            problems.push(found[f].clone())
    if read == 0:
        problems.push("no link records under out/: build the compiler first")
    var verdict = f"link records read: {read}\n"
    if os() != "Macos":
        verdict = verdict ++ "sandboxed builds: not checked on " ++ os() ++ " yet (the #1915 slice for it adds them)\n"
    else:
        let scratch = ht_join("out/command", ctx.target_name())
        let _clean = fs.remove_tree(scratch)
        let home = ht_join(root, ht_join(scratch, "home"))
        if fs.mkdir_all(ht_join(scratch, "home/tmp")) != 0:
            return ht_fail(ctx, "could not create " ++ scratch ++ "/home/tmp")
        let compiler = ht_join(root, inputs.get(0))
        let profile = ht_sandbox_profile()
        let fixtures: Vec[str] = Vec.new()
        fixtures.push("test/host_toolchain/hi.w")
        fixtures.push("test/host_toolchain/cimport_stdio.w")
        for i in 0..fixtures.len() as i32:
            let source = fixtures[i]
            let name = source.slice(source.find("host_toolchain/") + 15, source.len() - 2)
            let binary = ht_join(root, ht_join(scratch, name))
            let build: Vec[str] = Vec.new()
            build.push(compiler.clone())
            build.push("build")
            build.push(ht_join(root, source))
            build.push("-o")
            build.push(binary.clone())
            let built = ctx.process_runner().run_capture(ht_sandboxed(profile, home, build), ht_join(root, ht_join(scratch, name ++ ".build.stdout")), ht_join(root, ht_join(scratch, name ++ ".build.stderr")), 600000)
            if built.rc != 0:
                problems.push(source ++ ": the build failed with no host toolchain in reach (exit " ++ f"{built.rc}" ++ "):\n" ++ built.stdout ++ built.stderr)
                continue
            let run: Vec[str] = Vec.new()
            run.push(binary.clone())
            let ran = ctx.process_runner().run_capture(ht_sandboxed(profile, home, run), ht_join(root, ht_join(scratch, name ++ ".run.stdout")), ht_join(root, ht_join(scratch, name ++ ".run.stderr")), 60000)
            let expected = ht_expected_stdout(fs.read_text(source))
            if ran.rc != 0 or ran.stdout != expected:
                problems.push(source ++ f": the program exited {ran.rc} printing:\n" ++ ran.stdout ++ ran.stderr ++ "expected:\n" ++ expected)
                continue
            verdict = verdict ++ source ++ ": built and ran with no host toolchain\n"
    if problems.len() > 0:
        var message = f"{problems.len()} problem(s):"
        for i in 0..problems.len() as i32:
            message = message ++ "\n  " ++ problems[i]
        return ht_fail(ctx, message)
    if fs.write_text(output, verdict) != 0:
        return ht_fail(ctx, "could not write " ++ output)
    0
