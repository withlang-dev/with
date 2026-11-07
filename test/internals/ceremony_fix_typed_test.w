//! expect-stdout: ok

// #3061 slice 4: the census's typed patterns rewrite — `.clone()` on a str
// goes (D111), an explicit `&x` at a `&T` parameter goes (§3.8), `Some(x)`
// under an Option demand becomes `x` (D103). A clone of a List and a `&x`
// at a `T` parameter stay.
use CeremonyFix
use compiler.Compilation
use std.fs

let SAMPLE = "fn peek(s: &str) -> i64: s.len()\nfn take(n: i32) -> i32: n\nfn pick(flag: bool) -> Option[i32]:\n    if flag: Some(1) else: None\nfn main:\n    let name = \"ab\"\n    let twin = name.clone()\n    let xs = [1, 2]\n    let ys = xs.clone()\n    let k = 3\n    print(f\"{peek(&name)} {take(k)} {twin} {ys.len()} {pick(true).unwrap()}\")\n"

let EXPECTED = "fn peek(s: &str) -> i64: s.len()\nfn take(n: i32) -> i32: n\nfn pick(flag: bool) -> Option[i32]:\n    if flag: 1 else: None\nfn main:\n    let name = \"ab\"\n    let twin = name\n    let xs = [1, 2]\n    let ys = xs.clone()\n    let k = 3\n    print(f\"{peek(name)} {take(k)} {twin} {ys.len()} {pick(true).unwrap()}\")\n"

fn main:
    let path = "out/ceremony_fix_typed_sample.w"
    assert(write_file(path, SAMPLE) == 0)
    var comp = Compilation.init()
    let pool = comp.compile_entry_file(path)
    assert(pool.decl_count() > 0 and not comp.zcu.diagnostics.has_errors())
    let edits = cf_collect(comp.zcu.last_sema, pool, [], false)
    let mine = [e for e in edits if e.path == path]
    assert_eq(mine.len(), 4)
    let rewritten = cf_rewrite(SAMPLE, mine)
    assert_eq(rewritten, EXPECTED)
    assert(write_file(path, rewritten) == 0)
    var again = Compilation.init()
    let pool2 = again.compile_entry_file(path)
    assert(pool2.decl_count() > 0 and not again.zcu.diagnostics.has_errors())
    print("ok")
