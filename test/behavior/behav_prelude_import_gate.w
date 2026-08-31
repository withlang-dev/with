//! skip-on: windows issue #798: regex-literal codegen crash (0xC0000005) on native Windows
//! expect-stdout: ok

// D29 #750 scaffolding: non-§18.2 prelude-closure names resolve only through
// an explicit import. HashMap/StringBuilder/int_to_string are import-gated;
// the §18.2 names (Vec, Option, print, assert…) stay ambient; a regex literal
// is compiler lowering and never needs the import.
use std.collections.HashMap
use std.string.StringBuilder
use std.builtins.int_to_string

fn main:
    let m: HashMap[i32, i32] = HashMap.new()
    m.insert(1, 41)
    var sb = StringBuilder.new()
    sb.push_str(int_to_string((m.get(1).unwrap() + 1) as i64))
    assert(sb.to_str() == "42", "gated names work through explicit imports")
    let xs: Vec[i32] = Vec.new()
    xs.push(7)
    assert(xs.get(0) == 7, "§18.2 names stay ambient")
    let r = /ab+c/
    assert(r.is_match("abbc"), "regex literal lowers without an import")
    print("ok")
