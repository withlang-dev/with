// Runs tools/hooks/battery_guard.w over a TSV of `expected_rc<TAB>payload`
// lines and reports each mismatch: `with run tools/hooks/guard_cases.w
// <cases.tsv>`. The cases name a battery worktree that must be live in the
// slot registry for the blocks to apply.
use std.fs
use std.process

let cases = read_file(args()[1]).unwrap()
var failed = 0
var n = 0
for line in cases.split("\n"):
    if line.len() == 0: continue
    let parts = line.split("\t")
    let want: str = parts[0]
    let payload: str = parts[1]
    assert(write_file("out/guard-payload.json", payload) == 0)
    let got = run(&["sh", "-c", "with run tools/hooks/battery_guard.w < out/guard-payload.json 2>/dev/null"])
    n += 1
    if f"{got}" != want:
        failed += 1
        print(f"case {n}: expected rc={want}, got rc={got}: {payload}")
print(f"{n - failed} of {n} guard cases agree")
exit_code(if failed == 0: 0 else: 1)
