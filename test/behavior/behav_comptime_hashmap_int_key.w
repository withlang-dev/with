//! expect-stdout: ok

comptime fn build_int_map() -> HashMap[i32, str]:
    var m = HashMap[i32, str].new()
    m.insert(1, "one")
    m.insert(2, "two")
    m.insert(3, "three")
    m

comptime fn int_map_len() -> i64:
    var m = HashMap[i32, str].new()
    m.insert(10, "ten")
    m.insert(20, "twenty")
    m.len()

comptime fn int_map_contains_hit() -> bool:
    var m = HashMap[i32, str].new()
    m.insert(42, "answer")
    m.contains(42)

comptime fn int_map_contains_miss() -> bool:
    var m = HashMap[i32, str].new()
    m.insert(42, "answer")
    m.contains(99)

comptime fn int_map_remove_val() -> str:
    var m = HashMap[i32, str].new()
    m.insert(1, "first")
    m.insert(2, "second")
    m.remove(1)

comptime fn int_map_remove_len() -> i64:
    var m = HashMap[i32, str].new()
    m.insert(1, "first")
    m.insert(2, "second")
    let _ = m.remove(1)
    m.len()

const INT_MAP: HashMap[i32, str] = comptime build_int_map()
const INT_MAP_LEN: i64 = comptime int_map_len()
const INT_MAP_HIT: bool = comptime int_map_contains_hit()
const INT_MAP_MISS: bool = comptime int_map_contains_miss()
const INT_MAP_REMOVED: str = comptime int_map_remove_val()
const INT_MAP_REM_LEN: i64 = comptime int_map_remove_len()

fn main:
    assert(INT_MAP.len() == 3)
    assert(INT_MAP.get(1).unwrap() == "one")
    assert(INT_MAP.get(2).unwrap() == "two")
    assert(INT_MAP.get(3).unwrap() == "three")
    assert(INT_MAP_LEN == 2)
    assert(INT_MAP_HIT == true)
    assert(INT_MAP_MISS == false)
    assert(INT_MAP_REMOVED == "first")
    assert(INT_MAP_REM_LEN == 1)
    print("ok")
