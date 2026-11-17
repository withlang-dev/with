// Claude Code Stop hook: a turn does not end while the goal has work the
// agent may do.
//
// The rule "never end a turn while work remains" was prose three times
// (2026-10-31, 2026-11-15, 2026-11-17) and failed three times: the agent
// judged its own stop, at the end of a long turn, and a background wait on
// CI satisfied the letter of it. This is the check the agent does not run.
//
// A goal is active while `goal-prompt.md` exists at the project root (the
// maintainer writes it and removes it). While it is, the turn may end only
// when:
//   - a battery is running (its slot is live): the machine is taken, and
//     its completion wakes the agent; or
//   - no open issue is left that the agent may work: every open issue
//     carries `human attn needed`.
// Otherwise the stop is refused and the open issues are named, so the next
// action is one of them. An issue the agent cannot move is labelled
// `human attn needed`, with the reason in a comment: that is the only way
// to take it out of the queue, and it is visible to the maintainer.
//
// The queue is `gh issue list`; its last good answer is kept, and is used
// when GitHub cannot be reached (a failed lookup never opens the door).
// WITH_STOP_GUARD_QUEUE names a file to read the queue from instead (the
// cases file uses it).
//
// Exit 2 refuses the stop and shows the reason; anything else allows.
use std.io
use std.fs
use std.process

fn slot_dir -> str: env("HOME") ++ "/.local/with-green/battery-slots"

fn alive(pid: &str) -> bool: pid.len() > 0 and run_to_files(&["ps", "-p", pid.clone(), "-o", "pid="], "/dev/null", "/dev/null", 5000).code == 0

fn battery_running() -> bool:
    for i in 0..2:
        let path = slot_dir() ++ f"/{i}"
        if not file_exists(path): continue
        if alive((read_file(path) ?? "").split("\n")[0].split("\t")[0]): return true
    false

fn cache_path -> str: env("HOME") ++ "/.local/with-green/stop-guard-queue.tsv"

// `number<TAB>title` for each open issue the agent may work.
fn queue() -> str:
    let given = env("WITH_STOP_GUARD_QUEUE")
    if given.len() > 0: return read_file(given) ?? ""
    let out = env("HOME") ++ "/.local/with-green/stop-guard-queue.new"
    let listed = run_to_files(&["gh", "issue", "list", "--state", "open", "--limit", "500", "--json", "number,title,labels", "--jq", ".[] | select([.labels[].name] | index(\"human attn needed\") | not) | \"\\(.number)\\t\\(.title)\""], out, "/dev/null", 30000)
    if listed.code != 0: return read_file(cache_path()) ?? ""
    let text = read_file(out) ?? ""
    write_file(cache_path(), text)
    text

let root = env("CLAUDE_PROJECT_DIR")
if root.len() == 0 or not file_exists(root ++ "/goal-prompt.md"): exit_code(0)
if battery_running(): exit_code(0)

let open: List[str] = []
for line in queue().split("\n"):
    if line.len() > 0: open.push(line)
if open.len() == 0: exit_code(0)

eprint(f"stop guard: the goal is active and {open.len()} open issue(s) are yours to work. A wait on CI or on a ruling does not end a turn. Start one now:")
for i in 0..(if open.len() < 8: open.len() else: 8): eprint("  #" ++ open[i].replace("\t", "  "))
eprint("An issue you cannot move takes the label `human attn needed`, with the reason in a comment; nothing else removes it from this list.")
exit_code(2)
