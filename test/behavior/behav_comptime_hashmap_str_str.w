//! expect-stdout: ok

comptime fn build_str_str_map() -> HashMap[str, str]:
    var m = HashMap[str, str].new()
    m.insert("name", "alice")
    m.insert("city", "berlin")
    m.insert("lang", "with")
    m

comptime fn str_str_len() -> i64:
    var m = HashMap[str, str].new()
    m.insert("k1", "v1")
    m.insert("k2", "v2")
    m.len()

comptime fn str_str_contains_hit() -> bool:
    var m = HashMap[str, str].new()
    m.insert("key", "val")
    m.contains("key")

comptime fn str_str_contains_miss() -> bool:
    var m = HashMap[str, str].new()
    m.insert("key", "val")
    m.contains("other")

const SS_MAP: HashMap[str, str] = comptime build_str_str_map()
const SS_LEN: i64 = comptime str_str_len()
const SS_HIT: bool = comptime str_str_contains_hit()
const SS_MISS: bool = comptime str_str_contains_miss()

fn main:
    assert(SS_MAP.len() == 3)
    assert(SS_MAP.get("name").unwrap() == "alice")
    assert(SS_MAP.get("city").unwrap() == "berlin")
    assert(SS_MAP.get("lang").unwrap() == "with")
    assert(SS_LEN == 2)
    assert(SS_HIT == true)
    assert(SS_MISS == false)
    print("ok")
