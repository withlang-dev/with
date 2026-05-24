//! expect-stdout: ok

comptime fn build_map() -> HashMap[str, i32]:
    var m = HashMap[str, i32].new()
    m.insert("alpha", 1)
    m.insert("beta", 2)
    m.insert("gamma", 3)
    m

comptime fn map_len() -> i64:
    var m = HashMap[str, i32].new()
    m.insert("a", 10)
    m.insert("b", 20)
    m.len()

comptime fn map_contains_hit() -> bool:
    var m = HashMap[str, i32].new()
    m.insert("hello", 42)
    m.contains("hello")

comptime fn map_contains_miss() -> bool:
    var m = HashMap[str, i32].new()
    m.insert("hello", 42)
    m.contains("world")

comptime fn map_overwrite() -> i32:
    var m = HashMap[str, i32].new()
    m.insert("key", 100)
    m.insert("key", 200)
    m.get("key")

comptime fn map_overwrite_len() -> i64:
    var m = HashMap[str, i32].new()
    m.insert("key", 100)
    m.insert("key", 200)
    m.len()

comptime fn map_remove_val() -> i32:
    var m = HashMap[str, i32].new()
    m.insert("x", 10)
    m.insert("y", 20)
    m.remove("x")

comptime fn map_remove_len() -> i64:
    var m = HashMap[str, i32].new()
    m.insert("x", 10)
    m.insert("y", 20)
    let _ = m.remove("x")
    m.len()

comptime fn map_clear_len() -> i64:
    var m = HashMap[str, i32].new()
    m.insert("a", 1)
    m.insert("b", 2)
    m.clear()
    m.len()

const MAP: HashMap[str, i32] = comptime build_map()
const MAP_LEN: i64 = comptime map_len()
const MAP_HIT: bool = comptime map_contains_hit()
const MAP_MISS: bool = comptime map_contains_miss()
const MAP_OVERWRITE: i32 = comptime map_overwrite()
const MAP_OW_LEN: i64 = comptime map_overwrite_len()
const MAP_REMOVED: i32 = comptime map_remove_val()
const MAP_REM_LEN: i64 = comptime map_remove_len()
const MAP_CLR_LEN: i64 = comptime map_clear_len()

fn main:
    assert(MAP.len() == 3)
    assert(MAP.get("alpha").unwrap() == 1)
    assert(MAP.get("beta").unwrap() == 2)
    assert(MAP.get("gamma").unwrap() == 3)
    assert(MAP_LEN == 2)
    assert(MAP_HIT == true)
    assert(MAP_MISS == false)
    assert(MAP_OVERWRITE == 200)
    assert(MAP_OW_LEN == 1)
    assert(MAP_REMOVED == 10)
    assert(MAP_REM_LEN == 1)
    assert(MAP_CLR_LEN == 0)
    print("ok")
