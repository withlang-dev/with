//! expect-stdout: ok

comptime fn build_str_list() -> List[str]:
    var v = List[str].new()
    v.push("hello")
    v.push("world")
    v.push("foo")
    v

comptime fn str_len() -> i64:
    var v = List[str].new()
    v.push("a")
    v.push("b")
    v.len()

comptime fn str_contains_hit() -> bool:
    var v = List[str].new()
    v.push("hello")
    v.push("world")
    v.contains("world")

comptime fn str_contains_miss() -> bool:
    var v = List[str].new()
    v.push("hello")
    v.push("world")
    v.contains("missing")

comptime fn str_pop_val() -> str:
    var v = List[str].new()
    v.push("first")
    v.push("second")
    v.push("third")
    v.pop().unwrap()

comptime fn str_pop_len() -> i64:
    var v = List[str].new()
    v.push("first")
    v.push("second")
    v.push("third")
    let _ = v.pop()
    v.len()

comptime fn str_remove_val() -> str:
    var v = List[str].new()
    v.push("alpha")
    v.push("beta")
    v.push("gamma")
    v.remove(1)

comptime fn str_remove_len() -> i64:
    var v = List[str].new()
    v.push("alpha")
    v.push("beta")
    v.push("gamma")
    let _ = v.remove(1)
    v.len()

comptime fn str_clear_len() -> i64:
    var v = List[str].new()
    v.push("x")
    v.push("y")
    v.clear()
    v.len()

const STRS: List[str] = comptime build_str_list()
const STR_LEN: i64 = comptime str_len()
const STR_HIT: bool = comptime str_contains_hit()
const STR_MISS: bool = comptime str_contains_miss()
const STR_POPPED: str = comptime str_pop_val()
const STR_POP_LEN: i64 = comptime str_pop_len()
const STR_REMOVED: str = comptime str_remove_val()
const STR_REMOVE_LEN: i64 = comptime str_remove_len()
const STR_CLEAR_LEN: i64 = comptime str_clear_len()

fn main:
    assert(STRS.len() == 3)
    assert(STRS[0] == "hello")
    assert(STRS[1] == "world")
    assert(STRS[2] == "foo")
    assert(STR_LEN == 2)
    assert(STR_HIT == true)
    assert(STR_MISS == false)
    assert(STR_POPPED == "third")
    assert(STR_POP_LEN == 2)
    assert(STR_REMOVED == "beta")
    assert(STR_REMOVE_LEN == 2)
    assert(STR_CLEAR_LEN == 0)
    print("ok")
