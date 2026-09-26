// `with uat` — a project's acceptance scenarios (spec §18.5d, D67;
// docs/uat-plan.md): plain-text files under `uat/`, one scenario each, a
// header (`scenario:`, `requires:`, `platforms:`) and one step per line in
// the verbs a person would say at a terminal. The runner parses every
// scenario, skips the ones whose requirements this host cannot meet (with
// the reason), performs the rest step by step, and reports one verdict per
// scenario and one line per failed step. `expect (human):` is recorded and
// printed, never executed. Nothing here is a framework: the verbs are the
// runner's.
//
// Captures: out/uat/<scenario>/step-<N>.stdout|.stderr; the human checks:
// out/uat/human-checks.txt. `new directory` moves the scenario into
// out/uat/<scenario>/tmp/, deleted on pass unless `--keep`. `with` at the
// head of a `run:` line is the running toolchain, or `WITH_UAT_WITH`.

extern fn with_fs_write_file(path: &str, data: &str) -> i32
extern fn with_fs_mkdir_p(path: &str) -> i32
extern fn with_fs_read_file(path: &str) -> str
extern fn with_fs_file_exists(path: &str) -> i32
extern fn with_fs_remove_tree(path: &str) -> i32
extern fn with_fs_list_files(path: &str) -> str
use std.process
use TargetSpec
use std.time
use std.builtins.print
use std.builtins.eprint

extern fn with_exec_argv_capture_cwd(args: &str, stdout_path: &str, stderr_path: &str, timeout_ms: i32, cwd: &str) -> i32
extern fn with_exec_argv_capture_input(args: &str, stdout_path: &str, stderr_path: &str, timeout_ms: i32, stdin_path: &str) -> i32

const UAT_RUN_TIMEOUT_MS: i32 = 600000

// Verbs (the grammar of docs/uat-plan.md §3).
const UAT_NEW_DIRECTORY: i32 = 1
const UAT_RUN: i32 = 2
const UAT_RUN_FAILS: i32 = 3
const UAT_WRITE_FROM: i32 = 4
const UAT_WRITE_INLINE: i32 = 5
const UAT_COPY: i32 = 6
const UAT_ENV: i32 = 7
const UAT_STDIN: i32 = 8
const UAT_EXPECT_EXIT: i32 = 9
const UAT_EXPECT_STDOUT: i32 = 10
const UAT_EXPECT_STDOUT_CONTAINS: i32 = 11
const UAT_EXPECT_STDERR_CONTAINS: i32 = 12
const UAT_EXPECT_FILE_EXISTS: i32 = 13
const UAT_EXPECT_FILE_CONTAINS: i32 = 14
const UAT_EXPECT_IMAGE: i32 = 15
const UAT_EXPECT_HUMAN: i32 = 16

type UatStep {
    verb: i32,
    a: str,       // the verb's first operand: a command line, a path, a name, text
    b: str,       // its second: a fixture, a destination, a value, an int as text
    line: i32,    // 1-based, for the report
}

type UatScenario {
    name: str,            // the file stem
    path: str,
    title: str,
    requires: Vec[str],
    platforms: Vec[str],
    steps: Vec[UatStep],
    problem: str,         // a parse error, with its line already named
}

type UatRun {
    rc: i32,
    stdout: str,
    stderr: str,
    label: str,
}

// ── parsing ──────────────────────────────────────────────────────────────

fn uat_trim_trailing_line_endings(text: &str) -> str:
    var end = text.len()
    while end > 0 and (text[end - 1] == '\n' or text[end - 1] == '\r'):
        end = end - 1
    text.slice(0, end)

fn uat_split_list(text: &str) -> Vec[str]:
    var out: Vec[str] = Vec.new()
    for part in text.split(","):
        let t = part.trim()
        if t.len() > 0: out.push(t.clone())
    out

fn uat_rest_after(line: &str, prefix: &str) -> str: line.slice(prefix.len(), line.len()).trim().clone()

// The lines of an indented block after `at` (exclusive), de-indented by
// the first line's indentation; returns the block and the index of the
// first line after it.
fn uat_indented_block(lines: &Vec[str], at: i32) -> (str, i32):
    var i = at + 1
    var indent = -1
    var out = ""
    while i < lines.len() as i32:
        let raw = lines[i]
        if raw.trim().len() == 0:
            out = out ++ "\n"
            i = i + 1
            continue
        var spaces = 0
        while spaces < raw.len() as i32 and raw[spaces] == ' ': spaces = spaces + 1
        if spaces == 0:
            break
        if indent < 0: indent = spaces
        let cut = if spaces < indent: spaces else: indent
        out = out ++ raw.slice(cut, raw.len()) ++ "\n"
        i = i + 1
    // A block ends where the file does; trailing blank lines are not content.
    (uat_trim_trailing_line_endings(out) ++ "\n", i)

fn uat_step(verb: i32, a: str, b: str, line: i32) -> UatStep: UatStep { verb, a, b, line }

// A decimal integer with an optional sign; (false, 0) otherwise.
fn uat_parse_int(text: &str) -> (bool, i64):
    var i = 0
    var neg = false
    if text.len() > 0 and (text[0] == '-' or text[0] == '+'):
        neg = text[0] == '-'
        i = 1
    if i >= text.len() as i32: return (false, 0)
    var value: i64 = 0
    while i < text.len() as i32:
        let c = text[i]
        if c < '0' or c > '9': return (false, 0)
        value = value * 10 + (c - '0') as i64
        i = i + 1
    (true, if neg: 0 - value else: value)

fn uat_sort_strings(items: Vec[str]) -> Vec[str]:
    var sorted = move items
    for i in 1..sorted.len() as i32:
        var j = i
        while j > 0 and sorted[j - 1] > sorted[j]:
            let t = sorted[j - 1].clone()
            sorted[j - 1] = sorted[j].clone()
            sorted[j] = t
            j = j - 1
    sorted

fn uat_error(sc: UatScenario, line: i32, message: &str) -> UatScenario:
    var out = sc
    out.problem = f"{out.path}:{line}: {message}"
    out

fn uat_stem(path: &str) -> str:
    var start = 0
    for i in 0..path.len() as i32:
        if path[i] == '/': start = i + 1
    var end = path.len() as i32
    if path.ends_with(".uat"): end = end - 4
    path.slice(start, end).clone()

fn uat_parse(path: &str, text: &str) -> UatScenario:
    var sc = UatScenario { name: uat_stem(path), path: path.clone(), title: "", requires: Vec.new(), platforms: Vec.new(), steps: Vec.new(), problem: "" }
    var lines: Vec[str] = Vec.new()
    for raw in text.split("\n"):
        lines.push(uat_trim_trailing_line_endings(raw).clone())
    var i = 0
    var header_done = false
    while i < lines.len() as i32:
        let lineno = i + 1
        let line = lines[i].trim()
        if line.len() == 0 or line.starts_with("#"):
            i = i + 1
            continue
        if not header_done:
            if sc.title.len() == 0:
                if not line.starts_with("scenario:"):
                    return uat_error(move sc, lineno, "a scenario starts with 'scenario: <title>'")
                sc.title = uat_rest_after(line, "scenario:")
                if sc.title.len() == 0:
                    return uat_error(move sc, lineno, "'scenario:' needs a title")
                i = i + 1
                continue
            if line.starts_with("requires:"):
                sc.requires = uat_split_list(uat_rest_after(line, "requires:"))
                i = i + 1
                continue
            if line.starts_with("platforms:"):
                sc.platforms = uat_split_list(uat_rest_after(line, "platforms:"))
                i = i + 1
                continue
            header_done = true
        if line == "new directory":
            sc.steps.push(uat_step(UAT_NEW_DIRECTORY, "", "", lineno))
        else if line.starts_with("run (fails):"):
            sc.steps.push(uat_step(UAT_RUN_FAILS, uat_rest_after(line, "run (fails):"), "", lineno))
        else if line.starts_with("run:"):
            let cmd = uat_rest_after(line, "run:")
            if cmd.len() == 0:
                return uat_error(move sc, lineno, "'run:' needs a command")
            sc.steps.push(uat_step(UAT_RUN, cmd, "", lineno))
        else if line.starts_with("write "):
            let rest = uat_rest_after(line, "write ")
            let from = rest.find(" from ")
            if from >= 0:
                sc.steps.push(uat_step(UAT_WRITE_FROM, rest.slice(0, from).trim().clone(), rest.slice(from + 6, rest.len()).trim().clone(), lineno))
            else if rest.ends_with(":"):
                let (block, next) = uat_indented_block(lines, i)
                sc.steps.push(uat_step(UAT_WRITE_INLINE, rest.slice(0, rest.len() - 1).trim().clone(), block, lineno))
                i = next
                continue
            else:
                return uat_error(move sc, lineno, "'write' is 'write <path> from <fixture>' or 'write <path>:' followed by an indented block")
        else if line.starts_with("copy "):
            let rest = uat_rest_after(line, "copy ")
            let to = rest.find(" to ")
            if to < 0:
                return uat_error(move sc, lineno, "'copy' is 'copy <path> to <path>'")
            sc.steps.push(uat_step(UAT_COPY, rest.slice(0, to).trim().clone(), rest.slice(to + 4, rest.len()).trim().clone(), lineno))
        else if line.starts_with("env "):
            let rest = uat_rest_after(line, "env ")
            let eq = rest.find("=")
            if eq <= 0:
                return uat_error(move sc, lineno, "'env' is 'env NAME=value'")
            sc.steps.push(uat_step(UAT_ENV, rest.slice(0, eq).trim().clone(), rest.slice(eq + 1, rest.len()).trim().clone(), lineno))
        else if line == "stdin:":
            let (block, next) = uat_indented_block(lines, i)
            sc.steps.push(uat_step(UAT_STDIN, block, "", lineno))
            i = next
            continue
        else if line.starts_with("expect exit:"):
            let exit_text = uat_rest_after(line, "expect exit:")
            let (ok, _) = uat_parse_int(exit_text)
            if not ok:
                return uat_error(move sc, lineno, "'expect exit:' needs an integer")
            sc.steps.push(uat_step(UAT_EXPECT_EXIT, exit_text, "", lineno))
        else if line.starts_with("expect stdout contains:"):
            sc.steps.push(uat_step(UAT_EXPECT_STDOUT_CONTAINS, uat_rest_after(line, "expect stdout contains:"), "", lineno))
        else if line.starts_with("expect stdout:"):
            sc.steps.push(uat_step(UAT_EXPECT_STDOUT, uat_rest_after(line, "expect stdout:"), "", lineno))
        else if line.starts_with("expect stderr contains:"):
            sc.steps.push(uat_step(UAT_EXPECT_STDERR_CONTAINS, uat_rest_after(line, "expect stderr contains:"), "", lineno))
        else if line.starts_with("expect file "):
            let rest = uat_rest_after(line, "expect file ")
            if rest.ends_with(" exists"):
                sc.steps.push(uat_step(UAT_EXPECT_FILE_EXISTS, rest.slice(0, rest.len() - 7).trim().clone(), "", lineno))
            else:
                let at = rest.find(" contains:")
                if at < 0:
                    return uat_error(move sc, lineno, "'expect file' is 'expect file <path> exists' or 'expect file <path> contains: <text>'")
                sc.steps.push(uat_step(UAT_EXPECT_FILE_CONTAINS, rest.slice(0, at).trim().clone(), rest.slice(at + 10, rest.len()).trim().clone(), lineno))
        else if line.starts_with("expect image:"):
            return uat_error(move sc, lineno, "'expect image:' is not implemented yet (docs/uat-plan.md §5); record the check as 'expect (human):' meanwhile")
        else if line.starts_with("expect (human):"):
            sc.steps.push(uat_step(UAT_EXPECT_HUMAN, uat_rest_after(line, "expect (human):"), "", lineno))
        else:
            return uat_error(move sc, lineno, "not a step: '" ++ line ++ "' (the verbs are in uat/README.md)")
        i = i + 1
    if sc.title.len() == 0:
        return uat_error(move sc, 1, "a scenario starts with 'scenario: <title>'")
    sc

// A command line into argv: whitespace-separated, single or double quotes
// group, a backslash escapes the next character inside double quotes.
fn uat_split_command(text: &str) -> Vec[str]:
    var out: Vec[str] = Vec.new()
    var cur = ""
    var have = false
    var quote = 0
    var i = 0
    while i < text.len() as i32:
        let c = text[i]
        if quote != 0:
            if c == quote:
                quote = 0
            else if c == '\\' and quote == '"' and i + 1 < text.len() as i32:
                i = i + 1
                cur = cur ++ text.slice(i, i + 1)
            else:
                cur = cur ++ text.slice(i, i + 1)
        else if c == '\'' or c == '"':
            quote = c
            have = true
        else if c == ' ' or c == '\t':
            if have:
                out.push(cur)
                cur = ""
                have = false
        else:
            cur = cur ++ text.slice(i, i + 1)
            have = true
        i = i + 1
    if have: out.push(cur)
    out

fn uat_argv_blob(items: &Vec[str]) -> str:
    var out = ""
    for i in 0..items.len() as i32:
        out = out ++ items[i] ++ "\0"
    out

// ── host probes (`requires:`) ─────────────────────────────────────────────

fn uat_host_platform() -> str:
    let name = target_spec_os()
    if name == "Macos": return "darwin"
    if name == "Linux": return "linux"
    if name == "Windows": return "windows"
    name.clone()

fn uat_probe_capture(argv: &Vec[str], scratch: &str) -> i32:
    let _ = with_fs_mkdir_p(scratch)
    with_exec_argv_capture_cwd(uat_argv_blob(argv), scratch ++ "/probe.stdout", scratch ++ "/probe.stderr", 20000, ".")

// "" when the requirement is met, else the reason the scenario skips.
fn uat_unmet(req: &str, scratch: &str) -> str:
    if req == "network":
        if env("WITH_UAT_OFFLINE").len() > 0: return "requires network: WITH_UAT_OFFLINE is set"
        return ""
    if req == "display" or req == "opengl":
        if env("WITH_UAT_NO_DISPLAY").len() > 0: return "requires " ++ req ++ ": WITH_UAT_NO_DISPLAY is set"
        let host = uat_host_platform()
        if host == "linux" and env("DISPLAY").len() == 0 and env("WAYLAND_DISPLAY").len() == 0: return "requires " ++ req ++ ": none"
        if host == "darwin" and env("SSH_CONNECTION").len() > 0: return "requires " ++ req ++ ": none (ssh session)"
        return ""
    if req.starts_with("lib "):
        let name = req.slice(4, req.len()).trim()
        var argv: Vec[str] = Vec.new()
        argv.push("pkg-config")
        argv.push("--exists")
        argv.push(name.clone())
        if uat_probe_capture(argv, scratch) == 0: return ""
        for dir in ["/usr/include", "/usr/local/include", "/opt/homebrew/include"]:
            if with_fs_file_exists(dir ++ "/" ++ name ++ ".h") != 0 or with_fs_file_exists(dir ++ "/" ++ name ++ "/" ++ name ++ ".h") != 0: return ""
        return "requires lib " ++ name ++ ": not found"
    if req.starts_with("tool "):
        let name = req.slice(5, req.len()).trim()
        var argv: Vec[str] = Vec.new()
        argv.push(if uat_host_platform() == "windows": "where" else: "which")
        argv.push(name.clone())
        if uat_probe_capture(argv, scratch) == 0: return ""
        return "requires tool " ++ name ++ ": not on PATH"
    if req.starts_with("env "):
        let name = req.slice(4, req.len()).trim()
        if env(name).len() > 0: return ""
        return "requires env " ++ name ++ ": unset"
    "unknown requirement '" ++ req ++ "'"

fn uat_skip_reason(sc: &UatScenario, scratch: &str) -> str:
    if sc.platforms.len() > 0:
        let host = uat_host_platform()
        var listed = false
        for i in 0..sc.platforms.len() as i32:
            if sc.platforms[i] == host: listed = true
        if not listed: return "platforms: " ++ host ++ " not listed"
    for i in 0..sc.requires.len() as i32:
        let why = uat_unmet(sc.requires[i], scratch)
        if why.len() > 0: return why
    ""

// ── running ──────────────────────────────────────────────────────────────

type UatOutcome {
    verdict: str,     // "pass", "skip", "FAIL"
    detail: str,      // the failed step's line, or the skip reason
    stderr_path: str,
    steps: i32,
    human: Vec[str],
}

fn uat_join(dir: &str, path: &str) -> str:
    if path.starts_with("/"): return path.clone()
    if dir.ends_with("/"): dir ++ path else: dir ++ "/" ++ path

fn uat_dirname(path: &str) -> str:
    var cut = -1
    for i in 0..path.len() as i32:
        if path[i] == '/': cut = i
    if cut <= 0: "." else: path.slice(0, cut).clone()

fn uat_write_text(path: &str, text: &str) -> i32:
    let _ = with_fs_mkdir_p(uat_dirname(path))
    with_fs_write_file(path, text)

fn uat_read_text(path: &str) -> str: with_fs_read_file(path)

fn uat_fail(steps: i32, step: &UatStep, what: &str, stderr_path: &str, human: Vec[str]) -> UatOutcome:
    UatOutcome { verdict: "FAIL", detail: f"step {steps} (line {step.line}): {what}", stderr_path: stderr_path.clone(), steps, human }

// The toolchain a `run:` line's leading `with` names: WITH_UAT_WITH, else
// the running binary.
fn uat_toolchain(self_path: &str) -> str:
    let override = env("WITH_UAT_WITH")
    if override.len() > 0: override else: self_path.clone()

fn uat_run_scenario(sc: &UatScenario, root: &str, self_path: &str, keep: bool) -> UatOutcome:
    var human: Vec[str] = Vec.new()
    let capture_dir = uat_join(root, "out/uat/" ++ sc.name)
    let _ = with_fs_mkdir_p(capture_dir)
    var cwd = root.clone()
    var temp_dir = ""
    var stdin_text = ""
    var have_stdin = false
    var last = UatRun { rc: 0, stdout: "", stderr: "", label: "" }
    var have_run = false
    var steps = 0
    for si in 0..sc.steps.len() as i32:
        let step = &sc.steps[si]
        steps = steps + 1
        let verb = step.verb
        if verb == UAT_NEW_DIRECTORY:
            temp_dir = uat_join(capture_dir, "tmp")
            let _ = with_fs_remove_tree(temp_dir)
            if with_fs_mkdir_p(temp_dir) != 0: return uat_fail(steps, step, "could not create " ++ temp_dir, "", move human)
            cwd = temp_dir.clone()
        else if verb == UAT_RUN or verb == UAT_RUN_FAILS:
            var argv = uat_split_command(step.a)
            if argv.len() == 0: return uat_fail(steps, step, "empty command", "", move human)
            if argv[0] == "with": argv[0] = uat_toolchain(self_path)
            let label = f"step-{steps}"
            let stdout_path = uat_join(capture_dir, label ++ ".stdout")
            let stderr_path = uat_join(capture_dir, label ++ ".stderr")
            var rc = 0
            if have_stdin:
                if cwd != root:
                    return uat_fail(steps, step, "'stdin:' cannot follow 'new directory' yet: the runtime has no capture-with-input-and-cwd seam; put the stdin step before 'new directory'", "", move human)
                let stdin_path = uat_join(capture_dir, label ++ ".stdin")
                if uat_write_text(stdin_path, stdin_text) != 0: return uat_fail(steps, step, "could not write " ++ stdin_path, "", move human)
                rc = with_exec_argv_capture_input(uat_argv_blob(argv), stdout_path, stderr_path, UAT_RUN_TIMEOUT_MS, stdin_path)
                have_stdin = false
                stdin_text = ""
            else:
                rc = with_exec_argv_capture_cwd(uat_argv_blob(argv), stdout_path, stderr_path, UAT_RUN_TIMEOUT_MS, cwd)
            last = UatRun { rc, stdout: uat_read_text(stdout_path), stderr: uat_read_text(stderr_path), label: label.clone() }
            have_run = true
            if verb == UAT_RUN and rc != 0:
                return uat_fail(steps, step, "`run: " ++ step.a ++ "`: exit " ++ f"{rc}", stderr_path, move human)
            if verb == UAT_RUN_FAILS and rc == 0:
                return uat_fail(steps, step, "`run (fails): " ++ step.a ++ "`: exit 0, expected a failure", stderr_path, move human)
        else if verb == UAT_WRITE_FROM:
            let src = uat_join(root, "uat/fixtures/" ++ step.b)
            if with_fs_file_exists(src) == 0: return uat_fail(steps, step, "no fixture uat/fixtures/" ++ step.b, "", move human)
            if uat_write_text(uat_join(cwd, step.a), uat_read_text(src)) != 0: return uat_fail(steps, step, "could not write " ++ step.a, "", move human)
        else if verb == UAT_WRITE_INLINE:
            if uat_write_text(uat_join(cwd, step.a), step.b) != 0: return uat_fail(steps, step, "could not write " ++ step.a, "", move human)
        else if verb == UAT_COPY:
            let src = uat_join(root, step.a)
            if with_fs_file_exists(src) == 0: return uat_fail(steps, step, "nothing to copy at " ++ step.a, "", move human)
            if uat_write_text(uat_join(cwd, step.b), uat_read_text(src)) != 0: return uat_fail(steps, step, "could not write " ++ step.b, "", move human)
        else if verb == UAT_ENV:
            if set_env(step.a, step.b) != 0: return uat_fail(steps, step, "could not set " ++ step.a, "", move human)
        else if verb == UAT_STDIN:
            stdin_text = step.a.clone()
            have_stdin = true
        else if verb == UAT_EXPECT_HUMAN:
            human.push(step.a.clone())
        else:
            if not have_run and verb != UAT_EXPECT_FILE_EXISTS and verb != UAT_EXPECT_FILE_CONTAINS: return uat_fail(steps, step, "an 'expect' needs a 'run:' before it", "", move human)
            let err_path = if have_run: uat_join(capture_dir, last.label ++ ".stderr") else: ""
            if verb == UAT_EXPECT_EXIT:
                let (_, want) = uat_parse_int(step.a)
                if last.rc as i64 != want: return uat_fail(steps, step, f"exit {last.rc}, expected {want}", err_path, move human)
            else if verb == UAT_EXPECT_STDOUT:
                let actual = uat_trim_trailing_line_endings(last.stdout)
                if actual != step.a: return uat_fail(steps, step, "stdout was '" ++ actual ++ "', expected '" ++ step.a ++ "'", err_path, move human)
            else if verb == UAT_EXPECT_STDOUT_CONTAINS:
                if not last.stdout.contains(step.a): return uat_fail(steps, step, "stdout did not contain '" ++ step.a ++ "'", err_path, move human)
            else if verb == UAT_EXPECT_STDERR_CONTAINS:
                if not last.stderr.contains(step.a): return uat_fail(steps, step, "stderr did not contain '" ++ step.a ++ "'", err_path, move human)
            else if verb == UAT_EXPECT_FILE_EXISTS:
                if with_fs_file_exists(uat_join(cwd, step.a)) == 0: return uat_fail(steps, step, "no file " ++ step.a, err_path, move human)
            else if verb == UAT_EXPECT_FILE_CONTAINS:
                let p = uat_join(cwd, step.a)
                if with_fs_file_exists(p) == 0: return uat_fail(steps, step, "no file " ++ step.a, err_path, move human)
                if not uat_read_text(p).contains(step.b): return uat_fail(steps, step, step.a ++ " did not contain '" ++ step.b ++ "'", err_path, move human)
    if temp_dir.len() > 0 and not keep:
        let _ = with_fs_remove_tree(temp_dir)
    UatOutcome { verdict: "pass", detail: "", stderr_path: "", steps, human }

// ── the command ──────────────────────────────────────────────────────────

fn uat_dots(name: &str) -> str:
    var out = "uat: " ++ name ++ " "
    while out.len() < 50: out = out ++ "."
    out ++ " "

// A relative path made absolute against the shell's PWD: a scenario's
// `new directory` changes the cwd its commands run in, and the project
// root and a relative toolchain path must survive that. Without PWD it
// stays as it is.
fn uat_abs(path: &str) -> str:
    if path.starts_with("/"): return path.clone()
    let pwd = env("PWD")
    if pwd.len() == 0: return path.clone()
    if path == ".": pwd else: pwd ++ "/" ++ path

fn uat_project_root() -> str:
    // The project is the current directory (as `with test` and `with init`
    // take it); scenarios live in its `uat/`.
    uat_abs(".")

pub fn uat_list_scenarios(root: &str) -> Vec[str]:
    var out: Vec[str] = Vec.new()
    let listing = with_fs_list_files(uat_join(root, "uat"))
    for line in listing.split("\n"):
        let p = line.trim()
        if p.ends_with(".uat") and not p.contains("/fixtures/"): out.push(p.clone())
    uat_sort_strings(move out)

pub fn run_uat_command(argv: &Vec[str]) -> i32:
    var list_only = false
    var keep = false
    var wanted = ""
    for i in 2..argv.len() as i32:
        let a = argv[i]
        if a == "--list": list_only = true
        else if a == "--keep": keep = true
        else if a == "--help" or a == "-h":
            print("usage: with uat [<scenario>] [--list] [--keep]\n  runs the project's acceptance scenarios (uat/*.uat, spec §18.5d);\n  WITH_UAT_WITH=<path> names the toolchain a scenario's `with` runs")
            return 0
        else if a.starts_with("-"):
            eprint("error: unknown option '" ++ a ++ "' (with uat [<scenario>] [--list] [--keep])")
            return 2
        else if wanted.len() == 0: wanted = a.clone()
        else:
            eprint("error: one scenario name at most")
            return 2
    let root = uat_project_root()
    let paths = uat_list_scenarios(root)
    if paths.len() == 0:
        eprint("error: no scenarios: uat/*.uat is empty or missing (with init writes uat/hello.uat)")
        return 1
    let scratch = uat_join(root, "out/uat/.probe")
    var pass = 0
    var skip = 0
    var fail = 0
    var found = false
    var human_all = ""
    for pi in 0..paths.len() as i32:
        // Reported paths are the project's own (`uat/<name>.uat`).
        let shown = if paths[pi].starts_with(root ++ "/"): paths[pi].slice(root.len() + 1, paths[pi].len()) else: paths[pi].clone()
        let sc = uat_parse(shown, uat_read_text(paths[pi]))
        if wanted.len() > 0 and sc.name != wanted: continue
        found = true
        if sc.problem.len() > 0:
            print(uat_dots(sc.name) ++ "FAIL  " ++ sc.problem)
            fail = fail + 1
            continue
        let why = uat_skip_reason(sc, scratch)
        if list_only:
            var reqs = ""
            for ri in 0..sc.requires.len() as i32: reqs = reqs ++ (if ri > 0: ", " else: "") ++ sc.requires[ri]
            var plats = ""
            for qi in 0..sc.platforms.len() as i32: plats = plats ++ (if qi > 0: ", " else: "") ++ sc.platforms[qi]
            let applies = if why.len() == 0: "applies here" else: "skip (" ++ why ++ ")"
            print(uat_dots(sc.name) ++ applies ++ (if reqs.len() > 0: "  requires: " ++ reqs else: "") ++ (if plats.len() > 0: "  platforms: " ++ plats else: ""))
            continue
        if why.len() > 0:
            print(uat_dots(sc.name) ++ "skip  (" ++ why ++ ")")
            skip = skip + 1
            continue
        let started = now_ns()
        let self_path = if argv[0].contains("/"): uat_abs(argv[0]) else: argv[0].clone()
        let outcome = uat_run_scenario(sc, root, self_path, keep)
        let ms = (now_ns() - started) / 1000000
        if outcome.verdict == "pass":
            print(uat_dots(sc.name) ++ f"pass  ({outcome.steps} steps, {ms / 1000}.{(ms % 1000) / 100}s)")
            pass = pass + 1
        else:
            print(uat_dots(sc.name) ++ "FAIL  " ++ outcome.detail)
            if outcome.stderr_path.len() > 0:
                let tail = uat_trim_trailing_line_endings(uat_read_text(outcome.stderr_path))
                if tail.len() > 0:
                    var last_line = ""
                    for l in tail.split("\n"): last_line = l.clone()
                    let shown_err = if outcome.stderr_path.starts_with(root ++ "/"): outcome.stderr_path.slice(root.len() + 1, outcome.stderr_path.len()) else: outcome.stderr_path.clone()
                    print("        stderr: " ++ last_line ++ "  (" ++ shown_err ++ ")")
            fail = fail + 1
        for hi in 0..outcome.human.len() as i32:
            human_all = human_all ++ "  " ++ sc.name ++ ": " ++ outcome.human[hi] ++ "\n"
    if not found:
        eprint("error: no scenario named '" ++ wanted ++ "' in uat/")
        return 1
    if list_only: return 0
    var human_count = 0
    for l in human_all.split("\n"):
        if l.len() > 0: human_count = human_count + 1
    let total = pass + skip + fail
    var summary = f"uat: {total} scenario" ++ (if total == 1: "" else: "s") ++ f": {pass} pass"
    if skip > 0: summary = summary ++ f", {skip} skip"
    if fail > 0: summary = summary ++ f", {fail} FAIL"
    if human_count > 0: summary = summary ++ f"; {human_count} human check" ++ (if human_count == 1: "" else: "s") ++ " recorded"
    print(summary)
    if human_count > 0:
        print("human checks for this host:")
        print(uat_trim_trailing_line_endings(human_all))
        let _ = uat_write_text(uat_join(root, "out/uat/human-checks.txt"), human_all)
    if fail > 0: 1 else: 0
