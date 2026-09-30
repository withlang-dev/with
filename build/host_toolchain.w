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
// The sandbox is macOS's sandbox-exec, and on linux-x86_64 bubblewrap: the
// host's C headers (/usr/include), gcc (/usr/lib/gcc), glibc's crt objects
// and development link names, and every cc, gcc, ld and as are out of reach.
// The Windows slice of #1915 adds its own.

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
    if os() == "Linux":
        // bwrap: the host as it is, but for what ht_linux_masks() hides.
        argv.push("/usr/bin/bwrap")
        argv.push("--dev-bind")
        argv.push("/")
        argv.push("/")
        for m in profile.split("\n"):
            if m.len() == 0: continue
            if m.starts_with("dir "):
                argv.push("--tmpfs")
                argv.push(m.slice(4, m.len()).to_owned())
            else:
                argv.push("--ro-bind")
                argv.push("/dev/null")
                argv.push(m.slice(5, m.len()).to_owned())
        // The environment bwrap sets itself: /usr/bin, where env lives, is
        // one of the hidden directories.
        argv.push("--clearenv")
        for kv in ["HOME", "PATH", "TMPDIR"]:
            argv.push("--setenv")
            argv.push(kv.to_owned())
            argv.push(if kv == "HOME": home.to_owned() else if kv == "PATH": "/nonexistent" else: home ++ "/tmp")
        argv.push("--")
        for i in 0..command.len() as i32:
            argv.push(command[i].clone())
        return argv
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

// linux-x86_64: what the sandbox hides, one per line, "dir <path>" (an
// empty directory over it) or "file <path>" (/dev/null over it), for the
// paths this host has: every executable directory (no cc, gcc, ld, as or
// clang can run), the C headers, gcc's libraries and objects, and glibc's
// crt objects and development link scripts.
fn ht_linux_masks(fs: &ToolFs) -> str:
    var out = ""
    for d in ["/usr/bin", "/usr/sbin", "/usr/local/bin", "/usr/include", "/usr/local/include", "/usr/lib/gcc", "/usr/libexec/gcc", "/usr/lib/llvm"]:
        if fs.host_exists(d): out = out ++ "dir " ++ d ++ "\n"
    for name in ["crt1.o", "Scrt1.o", "crti.o", "crtn.o", "libc.so", "libm.so", "libc_nonshared.a"]:
        let path = "/usr/lib/x86_64-linux-gnu/" ++ name
        if fs.host_exists(path): out = out ++ "file " ++ path ++ "\n"
    out

// Copies test/host_toolchain/framework_project into the scratch directory
// with the dependency `with get` would have installed: .with/deps/c/cfstub/1.0
// whose metadata.json links -framework CoreFoundation from its Frameworks/
// directory, filled by `with __framework-stubs` in the sandbox. The source
// to build, or "error: <why>".
fn ht_setup_framework_project(ctx: &ActionCtx, scratch: &str, compiler: &str, profile: &str, home: &str) -> str:
    let fs = ctx.fs()
    let root = ctx.project_info().project_root()
    let dir = ht_join(scratch, "framework_project")
    let dep = ht_join(dir, ".with/deps/c/cfstub/1.0")
    if fs.mkdir_all(ht_join(dir, "src")) != 0 or fs.mkdir_all(dep) != 0:
        return "error: could not create " ++ dep
    if fs.write_text(ht_join(dir, "with.toml"), fs.read_text("test/host_toolchain/framework_project/with.toml")) != 0 or fs.write_text(ht_join(dir, "src/main.w"), fs.read_text("test/host_toolchain/framework_project/src/main.w")) != 0:
        return "error: could not copy test/host_toolchain/framework_project into " ++ dir
    var meta = "{\n  \"name\": \"cfstub\",\n  \"version\": \"1.0\",\n  \"include_paths\": [],\n  \"lib_paths\": [],\n  \"libs\": [],\n  \"defines\": [],\n"
    meta = meta ++ "  \"link_args\": [\"-framework\", \"CoreFoundation\"],\n  \"framework_paths\": [\"Frameworks\"],\n  \"requires\": []\n}\n"
    if fs.write_text(ht_join(dep, "metadata.json"), meta) != 0:
        return "error: could not write " ++ dep ++ "/metadata.json"
    let stubs: Vec[str] = Vec.new()
    stubs.push(compiler.to_owned())
    stubs.push("__framework-stubs")
    stubs.push(ht_join(root, ht_join(dep, "Frameworks")))
    stubs.push("CoreFoundation")
    let made = ctx.process_runner().run_capture(ht_sandboxed(profile, home, stubs), ht_join(root, ht_join(scratch, "framework_stubs.stdout")), ht_join(root, ht_join(scratch, "framework_stubs.stderr")), 300000)
    if made.rc != 0:
        return f"error: test/host_toolchain/framework_project: `with __framework-stubs` failed (exit {made.rc}):\n" ++ made.stdout ++ made.stderr
    ht_join(root, ht_join(dir, "src/main.w"))

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
    let linux = os() == "Linux" and arch() == "x86_64"
    if os() != "Macos" and not linux:
        verdict = verdict ++ "sandboxed builds: not checked on " ++ os() ++ "/" ++ arch() ++ " yet (the #1915 slice for it adds them)\n"
    else if linux and not fs.host_exists("/usr/bin/bwrap"):
        problems.push("the Linux sandbox needs bubblewrap (/usr/bin/bwrap); install it to run :no-host-toolchain")
    else:
        let scratch = ht_join("out/command", ctx.target_name())
        let _clean = fs.remove_tree(scratch)
        let home = ht_join(root, ht_join(scratch, "home"))
        if fs.mkdir_all(ht_join(scratch, "home/tmp")) != 0:
            return ht_fail(ctx, "could not create " ++ scratch ++ "/home/tmp")
        let compiler = ht_join(root, inputs.get(0))
        let profile = if linux: ht_linux_masks(fs) else: ht_sandbox_profile()
        // Each fixture: the repository file its expect-stdout lines come from,
        // the source built, and the binary's name.
        let fixtures: Vec[str] = Vec.new()
        let sources: Vec[str] = Vec.new()
        let names: Vec[str] = Vec.new()
        fixtures.push("test/host_toolchain/hi.w")
        sources.push(ht_join(root, "test/host_toolchain/hi.w"))
        names.push("hi")
        fixtures.push("test/host_toolchain/cimport_stdio.w")
        sources.push(ht_join(root, "test/host_toolchain/cimport_stdio.w"))
        names.push("cimport_stdio")
        // A project whose dependency links CoreFoundation, set up the way
        // `with get` installs one: metadata.json names the framework and the
        // stub directory, and the stub is generated from the running OS.
        let project = if linux: "error: skip" else: ht_setup_framework_project(ctx, scratch, compiler, profile, home)
        if project == "error: skip":
            verdict = verdict ++ "framework project: macOS only\n"
        else if project.starts_with("error: "):
            problems.push(project.slice(7, project.len()))
        else:
            fixtures.push("test/host_toolchain/framework_project/src/main.w")
            sources.push(project)
            names.push("framework_program")
        // #1915 (D81): `with get` builds from source with the SDK's cmake and
        // ninja, which the compiler carries; they run in the sandbox too.
        let tools_argv: Vec[str] = Vec.new()
        tools_argv.push(compiler.clone())
        tools_argv.push("__sdk-tools")
        let tools = ctx.process_runner().run_capture(ht_sandboxed(profile, home, tools_argv), ht_join(root, ht_join(scratch, "sdk-tools.stdout")), ht_join(root, ht_join(scratch, "sdk-tools.stderr")), 300000)
        let tools_dir = ht_trim(tools.stdout.replace("\n", ""))
        if tools.rc != 0 or tools_dir.len() == 0:
            problems.push(f"`with __sdk-tools` failed (exit {tools.rc}): " ++ tools.stdout ++ tools.stderr)
        else:
            for tool in ["cmake", "ninja"]:
                let run_tool: Vec[str] = Vec.new()
                run_tool.push(tools_dir ++ "/bin/" ++ tool)
                run_tool.push("--version")
                let ran_tool = ctx.process_runner().run_capture(ht_sandboxed(profile, home, run_tool), ht_join(root, ht_join(scratch, tool ++ ".stdout")), ht_join(root, ht_join(scratch, tool ++ ".stderr")), 60000)
                if ran_tool.rc != 0 or ran_tool.stdout.len() == 0:
                    problems.push("the SDK's " ++ tool ++ f" the compiler carries does not run (exit {ran_tool.rc}): " ++ ran_tool.stderr)
                else:
                    verdict = verdict ++ "SDK " ++ tool ++ " runs from the compiler's cache\n"
        // `with cc` compiles and links C, and C++ against the libc++ the
        // compiler carries, with its own clang, lld and sysroot (what `with get`
        // builds a package from source with).
        // C++ is the linux-x86_64 slice's (its sysroot carries libc++); the
        // darwin sysroot carries no libc++ headers yet.
        for which in 0..(if linux: 2 else: 1):
            let cc_source = if which == 0: "test/host_toolchain/cc_hello.c" else: "test/host_toolchain/cxx_hello.cpp"
            let cc_name = if which == 0: "cc_hello" else: "cxx_hello"
            let cc_binary = ht_join(root, ht_join(scratch, cc_name))
            let cc_argv: Vec[str] = Vec.new()
            cc_argv.push(compiler.clone())
            cc_argv.push("cc")
            if which == 1: cc_argv.push("--driver-mode=g++")
            cc_argv.push(ht_join(root, cc_source))
            cc_argv.push("-o")
            cc_argv.push(cc_binary.clone())
            if which == 0: cc_argv.push("-lm")
            let cc_built = ctx.process_runner().run_capture(ht_sandboxed(profile, home, cc_argv), ht_join(root, ht_join(scratch, cc_name ++ ".build.stdout")), ht_join(root, ht_join(scratch, cc_name ++ ".build.stderr")), 600000)
            if cc_built.rc != 0:
                problems.push(cc_source ++ f": `with cc` failed with no host toolchain in reach (exit {cc_built.rc}):\n" ++ cc_built.stdout ++ cc_built.stderr)
                continue
            let cc_run: Vec[str] = Vec.new()
            cc_run.push(cc_binary.clone())
            let cc_ran = ctx.process_runner().run_capture(ht_sandboxed(profile, home, cc_run), ht_join(root, ht_join(scratch, cc_name ++ ".run.stdout")), ht_join(root, ht_join(scratch, cc_name ++ ".run.stderr")), 60000)
            let cc_expected = ht_expected_stdout(fs.read_text(cc_source))
            if cc_ran.rc != 0 or cc_ran.stdout != cc_expected:
                problems.push(cc_source ++ f": the program exited {cc_ran.rc} printing:\n" ++ cc_ran.stdout ++ cc_ran.stderr ++ "expected:\n" ++ cc_expected)
            else:
                verdict = verdict ++ cc_source ++ ": `with cc` built it and it ran with no host toolchain\n"
        for i in 0..fixtures.len() as i32:
            let source = fixtures[i]
            let name = names[i].clone()
            let binary = ht_join(root, ht_join(scratch, name))
            let build: Vec[str] = Vec.new()
            build.push(compiler.clone())
            build.push("build")
            build.push(sources[i].clone())
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
