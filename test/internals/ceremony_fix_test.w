//! expect-stdout: ok

// #3061: `with fix-ceremony` over a program with every shape its first two
// passes decide — an annotation the initializer's type already gives (a
// read, an f-string, a non-generic call), one a literal needs (`3`, `[]`),
// a `var` rebound in a loop, a `var` only pushed into, and a `var` copied
// from — and the rewritten program still checks.
use CeremonyFix
use compiler.Compilation
use std.fs

let SAMPLE = "fn total(xs: &List[i32]) -> i64:\n    var n: i64 = 0\n    for x in xs: n = n + x\n    n\n\nfn label(k: i32) -> str:\n    let name: str = f\"item {k}\"\n    var other: str = name\n    let width: i32 = k\n    let twice: i64 = total([k, k])\n    let count: i64 = 3\n    var xs: List[i32] = []\n    xs.push(width)\n    f\"{other} {width} {twice} {count} {xs.len()}\"\n\nfn main:\n    print(label(2))\n"

let EXPECTED = "fn total(xs: &List[i32]) -> i64:\n    var n: i64 = 0\n    for x in xs: n = n + x\n    n\n\nfn label(k: i32) -> str:\n    let name = f\"item {k}\"\n    let other = name\n    let width = k\n    let twice = total([k, k])\n    let count: i64 = 3\n    let xs: List[i32] = []\n    xs.push(width)\n    f\"{other} {width} {twice} {count} {xs.len()}\"\n\nfn main:\n    print(label(2))\n"

fn main:
    let path = "out/ceremony_fix_sample.w"
    assert(write_file(path, SAMPLE) == 0)
    var comp = Compilation.init()
    let pool = comp.compile_entry_file(path)
    assert(pool.decl_count() > 0 and not comp.zcu.diagnostics.has_errors())
    let edits = cf_collect(comp.zcu.last_sema, pool, [], false)
    let mine = [e for e in edits if e.path == path]
    assert_eq(mine.len(), 6)
    let rewritten = cf_rewrite(SAMPLE, mine)
    assert_eq(rewritten, EXPECTED)
    assert(write_file(path, rewritten) == 0)
    var again = Compilation.init()
    let pool2 = again.compile_entry_file(path)
    assert(pool2.decl_count() > 0 and not again.zcu.diagnostics.has_errors())
    print("ok")
