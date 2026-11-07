//! expect-stdout: ok

// #3061 slice 3: `for i in 0..xs.len():` whose counter indexes only `xs`
// iterates the list; a loop that also uses the counter as a number, or
// writes through it, or indexes another list, stays.
use CeremonyFix
use compiler.Compilation
use std.fs

let SAMPLE = "fn main:\n    let parts = [\"a\", \"b\"]\n    let ws = [1, 2, 3]\n    var total = 0\n    for i in 0..parts.len():\n        print(parts[i])\n    for i in 0..ws.len():\n        total = total + ws[i] * i\n    for i in 0..ws.len():\n        ws[i] = ws[i] + 1\n    for i in 0..parts.len():\n        print(f\"{parts[i]} {ws[i]}\")\n    print(f\"{total}\")\n"

let EXPECTED = "fn main:\n    let parts = [\"a\", \"b\"]\n    let ws = [1, 2, 3]\n    var total = 0\n    for part in parts:\n        print(part)\n    for i in 0..ws.len():\n        total = total + ws[i] * i\n    for i in 0..ws.len():\n        ws[i] = ws[i] + 1\n    for i in 0..parts.len():\n        print(f\"{parts[i]} {ws[i]}\")\n    print(f\"{total}\")\n"

fn main:
    let path = "out/ceremony_fix_loops_sample.w"
    assert(write_file(path, SAMPLE) == 0)
    var comp = Compilation.init()
    let pool = comp.compile_entry_file(path)
    assert(pool.decl_count() > 0 and not comp.zcu.diagnostics.has_errors())
    let edits = cf_collect(comp.zcu.last_sema, pool, [], false)
    let mine = [e for e in edits if e.path == path]
    assert_eq(mine.len(), 2)
    let rewritten = cf_rewrite(SAMPLE, mine)
    assert_eq(rewritten, EXPECTED)
    assert(write_file(path, rewritten) == 0)
    var again = Compilation.init()
    let pool2 = again.compile_entry_file(path)
    assert(pool2.decl_count() > 0 and not again.zcu.diagnostics.has_errors())
    print("ok")
