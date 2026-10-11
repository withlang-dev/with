// The verdict of a gate, battery, drop-audit or test log, read once by a
// program instead of by eye: `with run tools/verdict.w <log> [<log>...]`.
//
// For each log: OPEN when no `rc=` line has been written yet (the command is
// still running), else `rc=N` and every target the driver reported as failed,
// or `green` when there are none. A battery status file is read the same way
// (its RED: lines are the targets).
use std.fs
use std.process

fn failed_target(line: &str) -> str:
    if line.starts_with("error: build.w test target failed: "): return line.slice(35, line.len()).trim().to_owned()
    if line.starts_with("  failed: "): return line.slice(10, line.len()).trim().to_owned()
    if line.starts_with("RED: "): return line.slice(5, line.len()).trim().to_owned()
    if line.starts_with("error:   failed: "): return line.slice(17, line.len()).trim().to_owned()
    if line.contains(" failed in '"): return line.split(" failed in '")[1].split("'")[0].to_owned()
    let quoted = (line.starts_with("error: ") and line.contains(" target '") and line.contains("' failed")) or line.starts_with("survey: skipping '")
    if not quoted: return ""
    let parts = line.split("'")
    if parts.len() < 2: return ""
    parts[1].to_owned()

// `--detail <needle>` also prints the failing block: from each line naming
// the needle (a red target or test path) through the next blank line, at
// most 60 lines, so a red is diagnosed from the tool and never by eye.
let argv = args()
var paths: List[str] = List.new()
var detail = ""
var progress = false
var i = 1
while i < argv.len():
    if argv[i] == "--detail" and i + 1 < argv.len():
        detail = argv[i + 1]
        i = i + 2
        continue
    // `--times` prints the driver's wall-time lines, so a slow phase is
    // located from the tool and never by eye.
    if argv[i] == "--times":
        detail = " wall "
        i = i + 1
        continue
    // `--progress` prints the driver's step lines: every target start
    // (the first `[compile] <target>` line), finish (`[build]`, `[time]`,
    // `ok:`, `test target`), `gate:` and `error` lines, with line numbers,
    // so where a run is and what it did is read from the tool.
    if argv[i] == "--progress":
        progress = true
        i = i + 1
        continue
    paths.push(argv[i])
    i = i + 1
if paths.len() == 0:
    eprint("usage: with run tools/verdict.w [--detail <needle>] <log>...")
    exit_code(2)
var worst = 0
for pi in 0..paths.len():
    let path: str = paths[pi]
    let text = read_file(path) ?? ""
    if text.len() == 0:
        print(f"{path}: MISSING")
        worst = 2
        continue
    var rc = ""
    var reds: List[str] = List.new()
    var done = false
    for line in text.split("\n"):
        if line.starts_with("rc="): rc = line.slice(3, line.len()).trim().to_owned()
        if line.starts_with("BATTERY_DONE"): done = true
        let t = failed_target(line)
        if t.len() > 0 and not reds.contains(t): reds.push(t)
    if progress:
        var seen_targets: List[str] = List.new()
        var ln = 0
        var offset: i64 = 0
        for line in text.split("\n"):
            ln = ln + 1
            offset = offset + line.len() + 1
            let t = line.trim()
            if t.starts_with("[compile] "):
                let parts = t.split(" ")
                if parts.len() < 2: continue
                let target = parts[1].to_owned()
                if seen_targets.contains(target): continue
                seen_targets.push(target)
                print(f"{ln}@{offset}: start {target}")
            else if t.starts_with("[build]") or t.starts_with("[time]") or t.starts_with("ok:") or t.starts_with("test target") or t.starts_with("gate:") or t.starts_with("error") or t.starts_with("survey:"):
                print(f"{ln}@{offset}: {t}")
        print(f"{path}: {ln} lines")
    if detail.len() > 0:
        let lines = text.split("\n")
        var li = 0
        while li < lines.len():
            if lines[li].contains(detail):
                print(f"--- {path}: {detail} at line {li + 1}")
                var shown = 0
                while li < lines.len() and shown < 60 and (shown == 0 or lines[li].trim().len() > 0):
                    print(lines[li])
                    li = li + 1
                    shown = shown + 1
                continue
            li = li + 1
    if rc.len() == 0 and not done:
        print(f"{path}: OPEN (still running; no rc line yet)" ++ (if reds.len() > 0: "; RED so far: " ++ reds.join(" ") else: ""))
        worst = 1
        continue
    let verdict = if reds.len() == 0 and (rc == "0" or rc.len() == 0): "green" else: "RED " ++ reds.join(" ")
    print(f"{path}: rc={rc} {verdict}")
    if verdict != "green": worst = 1
exit_code(worst)
