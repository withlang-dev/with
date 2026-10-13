// stack_status -- the generated half of a handoff: everything about the
// current stack that git, gh, and the battery already know, printed fresh
// instead of copied by hand into a handoff document that goes stale.
//
//   with run tools/stack_status.w
//
// Prints the branch and HEAD, the commits ahead of origin/main, tracked
// dirtiness, the branch's PR (when gh finds one), the battery status file,
// and the newest battery run log's verdict line. What it deliberately does
// not print is judgment: what to do next, which reds are pre-existing, and
// why — that stays the human-written part of a handoff.

use std.fs
use std.process

fn capture(argv: &List[str], name: &str) -> str:
    assert(mkdir_p("out/stack-status") == 0)
    let done = run_to_files_in(".", argv, f"out/stack-status/{name}.txt", f"out/stack-status/{name}.err")
    if done.code != 0: return ""
    read_file(f"out/stack-status/{name}.txt") ?? ""

fn first_line(text: &str) -> str:
    for line in text.split("\n"):
        if line.len() > 0: return line
    ""

fn git(args: &List[str], name: &str) -> str:
    var argv: List[str] = List.new()
    argv.push("git")
    for a in args: argv.push(a)
    capture(&argv, name)

fn main:
    var branch_args: List[str] = List.new()
    branch_args.push("branch")
    branch_args.push("--show-current")
    let branch = first_line(git(&branch_args, "branch"))
    var head_args: List[str] = List.new()
    head_args.push("rev-parse")
    head_args.push("--short")
    head_args.push("HEAD")
    let head = first_line(git(&head_args, "head"))
    print(f"branch: {if branch.len() > 0: branch else: "(detached)"} at {head}")
    var log_args: List[str] = List.new()
    log_args.push("log")
    log_args.push("--oneline")
    log_args.push("origin/main..HEAD")
    let ahead = git(&log_args, "ahead")
    var ahead_count = 0
    for line in ahead.split("\n"):
        if line.len() > 0: ahead_count = ahead_count + 1
    print(f"commits ahead of origin/main: {ahead_count}")
    for line in ahead.split("\n"):
        if line.len() > 0: print(f"  {line}")
    var status_args: List[str] = List.new()
    status_args.push("status")
    status_args.push("--porcelain")
    var dirty = 0
    var untracked = 0
    for line in git(&status_args, "status").split("\n"):
        if line.len() == 0: continue
        if line.starts_with("?? "): untracked = untracked + 1
        else: dirty = dirty + 1
    print(f"worktree: {dirty} tracked changes, {untracked} untracked")
    if branch.len() > 0:
        var pr_argv: List[str] = List.new()
        pr_argv.push("gh")
        pr_argv.push("pr")
        pr_argv.push("view")
        pr_argv.push(branch)
        pr_argv.push("--json")
        pr_argv.push("number,state,isDraft,url,title")
        let pr = first_line(capture(&pr_argv, "pr"))
        print(f"pr: {if pr.len() > 0: pr else: "none found by gh"}")
    let battery_status = read_file("out/battery/status.txt") ?? ""
    if battery_status.len() > 0:
        print("battery (out/battery/status.txt):")
        for line in battery_status.split("\n"):
            if line.len() > 0: print(f"  {line}")
    else:
        print("battery: no out/battery/status.txt (no battery run in this worktree)")
    var newest = ""
    var newest_rc = ""
    for n in 1..13:
        let path = f"out/battery-run{n}.log"
        let text = read_file(path) ?? ""
        if text.len() == 0: continue
        newest = path
        newest_rc = "OPEN (no rc line yet)"
        for line in text.split("\n"):
            if line.starts_with("rc="): newest_rc = line
    if newest.len() > 0: print(f"newest battery log: {newest} ({newest_rc}); full verdict: with run ~/.claude/hooks/verdict.w out/battery/status.txt {newest}")
