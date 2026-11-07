//! expect-stdout: ok

// #3061 slice 2: a widening cast under a demand of its target goes; a
// `List.new()` / `HashMap.new()` / `HashSet.new()` under a written type is
// the empty literal (D93); a narrowing cast, a cast that types a binding,
// and a constructor without a written type all stay.
use CeremonyFix
use compiler.Compilation
use std.fs

let SAMPLE = "use std.collections.HashMap\nuse std.collections.HashSet\nfn wide(n: i64) -> i64: n\nfn narrow(n: i32) -> i32: n\nfn main:\n    let k: i32 = 3\n    let a = wide(k as i64)\n    let b = narrow(a as i32)\n    let c = k as i64\n    let xs: List[i32] = List.new()\n    let m: HashMap[str, i32] = HashMap.new()\n    let s: HashSet[i32] = HashSet.new()\n    let ys = List.new()\n    ys.push(1)\n    xs.push(k)\n    print(f\"{a} {b} {c} {xs.len()} {m.len()} {s.len()} {ys.len()}\")\n"

let EXPECTED = "use std.collections.HashMap\nuse std.collections.HashSet\nfn wide(n: i64) -> i64: n\nfn narrow(n: i32) -> i32: n\nfn main:\n    let k: i32 = 3\n    let a = wide(k)\n    let b = narrow(a as i32)\n    let c = k as i64\n    let xs: List[i32] = []\n    let m: HashMap[str, i32] = [:]\n    let s: HashSet[i32] = []\n    let ys = List.new()\n    ys.push(1)\n    xs.push(k)\n    print(f\"{a} {b} {c} {xs.len()} {m.len()} {s.len()} {ys.len()}\")\n"

fn main:
    let path = "out/ceremony_fix_casts_sample.w"
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
