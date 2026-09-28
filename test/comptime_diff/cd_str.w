//! expect-stdout: ok

// Comptime differential: every str method must produce the same answer at
// comptime and at runtime. The spec-inventory checker computed wrong sets
// for months because nothing compared the two.

comptime fn str_battery(s: str) -> i32:
    var acc = 0
    acc = acc + s.len() as i32
    if s.contains("ok"): acc = acc + 100
    if s.starts_with("in"): acc = acc + 200
    if s.ends_with("ce"): acc = acc + 400
    acc = acc + s.find("var") as i32
    acc = acc + s.byte_at(3)
    acc = acc + s.slice(2, 8).len() as i32
    acc = acc + s.replace("a", "bb").len() as i32
    let parts = s.split("a")
    acc = acc + parts.len() as i32 * 10
    acc

// The rest of the intrinsic set (#1866): the build layer trims and indexes
// seed.lock lines under the seed's evaluator whenever the native runner
// cannot be linked yet.
comptime fn str_battery_2(s: str) -> i32:
    var acc = 0
    let t = s.trim()
    acc = acc + t.len() as i32
    if t.starts_with("in") and t.ends_with("ce"): acc = acc + 1000
    if s.trim() == s: acc = acc + 5000
    acc = acc + s.index_of("ok") as i32
    acc = acc + s.index_of("missing") as i32
    acc = acc + s.to_upper().byte_at(3)
    acc = acc + s.to_lower().byte_at(3)
    if s.to_upper().to_lower() == s: acc = acc + 3000
    acc = acc + s.repeat(3).len() as i32
    if s.repeat(0).len() == 0: acc = acc + 7000
    acc

const CT_STR: i32 = comptime str_battery("invariance-ok-var-dance")
const CT_STR_2: i32 = comptime str_battery_2(" \t invariance-OK-var-dance\n")
const CT_STR_3: i32 = comptime str_battery_2("invariance-ok-var-dance")

fn main:
    assert(CT_STR == str_battery("invariance-ok-var-dance"))
    assert(CT_STR_2 == str_battery_2(" \t invariance-OK-var-dance\n"))
    assert(CT_STR_3 == str_battery_2("invariance-ok-var-dance"))
    print("ok")
