//! expect-stdout: ok

// D22: a join of Option[&i64] eliminators with a bare literal arm takes the
// payload's width — the literal adapts. Regression pin for the i32-anchored
// join that truncated the materialized pointee to 32 bits (the
// analyze-audit segfault class: fn_fn_types handles lost bit 32+).
fn main:
    var m: HashMap[i32, i64] = HashMap.new()
    m.insert(7, 5000000123)
    let raw = m.get(7)
    let missing = m.get(8)
    let v = if raw.is_some(): raw.unwrap() else: if missing.is_some(): missing.unwrap() else: 0
    assert(v == 5000000123)
    let direct = if missing.is_some(): missing.unwrap() else: if raw.is_some(): raw.unwrap() else: 0
    assert(direct == 5000000123)
    print("ok")
