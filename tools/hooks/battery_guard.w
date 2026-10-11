// Claude Code PreToolUse hook: a worktree with a live battery is read-only.
//
// The battery registry (~/.local/with-green/battery-slots/{0,1}, written by
// tools/battery.w as `pid<TAB>worktree<TAB>head`) names every running
// battery. While one runs, this hook refuses, in that worktree:
//   - any Edit/Write (the gate and the survey measure the committed tree;
//     an edit under a running battery produced a false red, 2026-10-10);
//   - a `with build` / `src/main build` run there (`cd <root>` before it, or
//     the build's own path under it): the build lock collides, and the
//     battery's own build is what is being measured;
//   - a kill of the battery's pid or a pkill naming the battery (a battery
//     stopped mid-survey loses the full red list, and the next battery
//     rediscovers the reds one at a time);
//   - git commands that change the tree, run there (`cd <root>` or `-C`);
//   - mv/rm/cp of, or a redirect into, a path under it.
// It also refuses reading a gate or battery log with grep/tail/cat/head:
// `with run tools/verdict.w <log>` prints the verdict, so a log is never
// misread by eye (a gate read as finished started a battery into its lock).
//
// Exit 2 blocks the tool call and shows the reason; anything else allows.
use std.io
use std.json
use std.fs
use std.process

fn slot_dir -> str: env("HOME") ++ "/.local/with-green/battery-slots"

fn alive(pid: &str) -> bool: pid.len() > 0 and run_to_files(&["ps", "-p", pid.clone(), "-o", "pid="], "/dev/null", "/dev/null", 5000).code == 0

// `pid<TAB>root` for each live battery.
fn live_batteries() -> List[(str, str)]:
    var out: List[(str, str)] = List.new()
    for i in 0..2:
        let path = slot_dir() ++ f"/{i}"
        if not file_exists(path): continue
        let line = (read_file(path) ?? "").split("\n")[0].to_owned()
        let fields = line.split("\t")
        if fields.len() < 2: continue
        if alive(fields[0]): out.push((fields[0].to_owned(), fields[1].to_owned()))
    out

fn refuse(why: &str) -> Never:
    eprint("battery guard: " ++ why)
    exit_code(2)

// The command split at whitespace, with `;`, `&&`, `||` and `|` as their own
// tokens so a verb's arguments end at the next command.
fn tokens(command: &str) -> List[str]:
    var out: List[str] = List.new()
    for raw in command.replace(";", " ; ").replace("&&", " && ").replace("||", " || ").replace("|", " | ").replace("\n", " ").split(" "):
        if raw.len() > 0: out.push(raw.to_owned())
    out

fn is_break(t: &str) -> bool: t == ";" or t == "&&" or t == "||" or t == "|"

fn under(path: &str, root: &str) -> bool: path == root or path.starts_with(root ++ "/")

// Whether a command runs (after a `cd`, or `git -C`) inside `root`.
fn runs_in(ts: &List[str], root: &str) -> bool:
    for i in 0..ts.len() - 1:
        if (ts[i] == "cd" or ts[i] == "-C") and under(ts[i + 1], root): return true
    false

let payload = read_all()
if payload.trim().len() == 0: exit_code(0)
let doc = JsonDocument.parse(payload)
let root = doc.root()
let tool: str = root.field("tool_name").raw()
let input = root.field("tool_input")
let batteries = live_batteries()
if batteries.len() == 0: exit_code(0)

if tool == "Edit" or tool == "Write" or tool == "MultiEdit" or tool == "NotebookEdit":
    let path: str = if tool == "NotebookEdit": input.field("notebook_path").raw() else: input.field("file_path").raw()
    for (pid, r) in batteries:
        if under(path, r):
            refuse(f"{r} has a live battery (pid {pid}); the tree it measures is read-only until it exits (with run tools/verdict.w {r}/out/battery/status.txt)")
    exit_code(0)

if tool != "Bash": exit_code(0)
let command: str = input.field("command").raw()
let ts = tokens(command)
for (pid, r) in batteries:
    let inside = runs_in(&ts, r)
    for i in 0..ts.len():
        let t: str = ts[i]
        let next: str = if i + 1 < ts.len(): ts[i + 1] else: ""
        let prev: str = if i > 0: ts[i - 1] else: ""
        if t == "build" and (prev == "with" or prev.ends_with("/main") or prev.ends_with("/with")) and (inside or (next.len() > 0 and under(next, r))):
            refuse(f"{r} has a live battery (pid {pid}); a build there collides with its lock and changes what it measures")
        if t == "kill" or t == "pkill":
            var j = i + 1
            while j < ts.len() and not is_break(ts[j]):
                if ts[j] == pid or ts[j].contains("battery") or ts[j].contains("build"): refuse(f"a battery (pid {pid}) in {r} is not stopped mid-survey: its full red list is what the next battery would otherwise rediscover one at a time")
                j += 1
        if t == "git" and inside:
            var k = i + 1
            while k < ts.len() and not is_break(ts[k]):
                let sub: str = ts[k]
                if sub == "commit" or sub == "checkout" or sub == "rebase" or sub == "reset" or sub == "merge" or sub == "stash" or sub == "mv" or sub == "rm" or sub == "pull" or sub == "switch":
                    refuse(f"{r} has a live battery (pid {pid}); `git {sub}` there changes the tree it measures")
                k += 1
        if t == "mv" or t == "rm" or t == "cp":
            var m = i + 1
            while m < ts.len() and not is_break(ts[m]):
                if under(ts[m], r) or (inside and not ts[m].starts_with("/") and not ts[m].starts_with("-")): refuse(f"{r} has a live battery (pid {pid}); `{t}` of a file there changes what it measures")
                m += 1
        if (t == ">" or t == ">>") and next.len() > 0 and (under(next, r) or (inside and not next.starts_with("/"))):
            refuse(f"{r} has a live battery (pid {pid}); writing into it changes what it measures")
        let target = if t.starts_with(">>"): t.slice(2, t.len()) else if t.starts_with(">"): t.slice(1, t.len()) else: ""
        if target.len() > 0 and under(target, r):
            refuse(f"{r} has a live battery (pid {pid}); writing into it changes what it measures")
let log_readers = ["grep", "tail", "cat", "head", "less", "more"]
for i in 0..ts.len():
    let t: str = ts[i]
    if not log_readers.contains(t): continue
    var j = i + 1
    while j < ts.len() and not is_break(ts[j]):
        let a: str = ts[j]
        if a.ends_with("out/gate.log") or a.contains("out/battery/") or a.ends_with("battery-run.log") or a.ends_with("drop-audit-run.log") or a.ends_with("dev-build.log"):
            refuse("read a gate, build or battery log with `with run tools/verdict.w <log>`, never by eye: it prints the exit line and every red target, or OPEN while the log is still being written")
        j += 1
exit_code(0)
