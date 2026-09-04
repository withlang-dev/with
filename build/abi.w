// ABI-hash check (docs/with-abi.md §7, decisions.md D38).
//
// The With ABI's rules live in src/FnAbi.w and src/TypeLayout.w. Their
// sha256s are recorded in docs/with-abi.sha256 next to the version they
// belong to. A change to either file without re-recording the hash — which
// is the moment WITH_ABI_VERSION must be bumped — fails the battery here,
// so an ABI change cannot land unnoticed and a .wo bundle built under the
// old version cannot be linked under a silently different convention.
use std.build

fn abi_owned_text(s: &str): s ++ ""

fn abi_split_lines(text: &str) -> Vec[str]:
    let out: Vec[str] = Vec.new()
    var start: i64 = 0
    var i: i64 = 0
    while i < text.len():
        if text[i] == '\n':
            out.push(text.slice(start, i))
            start = i + 1
        i = i + 1
    if start < text.len():
        out.push(text.slice(start, text.len()))
    out

pub fn run_abi_hash_check_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let record_path = "docs/with-abi.sha256"
    let record = if fs.exists(record_path): fs.read_text(record_path) else: ""
    if record.len() == 0:
        ctx.diagnostics().error("abi-hash-check: missing " ++ record_path ++ " (record it with the current hashes of src/FnAbi.w and src/TypeLayout.w)")
        return 1
    var checked = 0
    var report = ""
    var failed = false
    for line in abi_split_lines(record):
        if line.len() == 0 or line.starts_with("#"): continue
        // "<sha256>  <path>" — the shasum(1) format.
        let parts = line.split("  ")
        if parts.len() != 2:
            ctx.diagnostics().error("abi-hash-check: malformed line in " ++ record_path ++ ": " ++ line)
            return 1
        let expected = abi_owned_text(parts.get(0))
        let path = abi_owned_text(parts.get(1))
        let actual = fs.sha256_file(path)
        if actual.len() == 0:
            ctx.diagnostics().error("abi-hash-check: cannot hash " ++ path)
            return 1
        if actual != expected:
            failed = true
            report = report ++ "  " ++ path ++ ": recorded " ++ expected.slice(0, 16) ++ "… current " ++ actual.slice(0, 16) ++ "…\n"
        checked = checked + 1
    if failed:
        ctx.diagnostics().error("abi-hash-check: an ABI-defining source changed and docs/with-abi.sha256 was not re-recorded (docs/abi_roadmap.md Level 0 — this hash keys every .wo bundle):\n" ++ report ++ "  Re-record consciously with `shasum -a 256 src/FnAbi.w src/TypeLayout.w > docs/with-abi.sha256`; every .wo rebuilds once.\n  If the convention itself changed, also bump the WITH_ABI_VERSION label in src/FnAbi.w and add a docs/with-abi.md version-history entry.")
        return 1
    if checked == 0:
        ctx.diagnostics().error("abi-hash-check: " ++ record_path ++ " records no files")
        return 1
    if fs.write_text(ctx.output(), f"ok {checked} files\n") != 0:
        return 1
    0
