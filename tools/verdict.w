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
    let quoted = (line.starts_with("error: ") and line.contains(" target '") and line.contains("' failed")) or line.starts_with("survey: skipping '")
    if not quoted: return ""
    let parts = line.split("'")
    if parts.len() < 2: return ""
    parts[1].to_owned()

let paths = args()
if paths.len() < 2:
    eprint("usage: with run tools/verdict.w <log>...")
    exit_code(2)
var worst = 0
for i in 1..paths.len():
    let path: str = paths[i]
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
    if rc.len() == 0 and not done:
        print(f"{path}: OPEN (still running; no rc line yet)")
        worst = 1
        continue
    let verdict = if reds.len() == 0 and (rc == "0" or rc.len() == 0): "green" else: "RED " ++ reds.join(" ")
    print(f"{path}: rc={rc} {verdict}")
    if verdict != "green": worst = 1
exit_code(worst)
