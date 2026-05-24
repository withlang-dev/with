//! expect-stdout: ok

comptime fn build_bool_vec() -> Vec[bool]:
    var v = Vec[bool].new()
    v.push(true)
    v.push(false)
    v.push(true)
    v

comptime fn bool_len() -> i64:
    var v = Vec[bool].new()
    v.push(true)
    v.push(false)
    v.len()

comptime fn bool_contains_hit() -> bool:
    var v = Vec[bool].new()
    v.push(true)
    v.contains(true)

comptime fn bool_contains_miss() -> bool:
    var v = Vec[bool].new()
    v.push(true)
    v.contains(false)

comptime fn bool_pop_val() -> bool:
    var v = Vec[bool].new()
    v.push(true)
    v.push(false)
    v.pop()

comptime fn bool_pop_len() -> i64:
    var v = Vec[bool].new()
    v.push(true)
    v.push(false)
    v.push(true)
    let _ = v.pop()
    v.len()

comptime fn bool_remove_val() -> bool:
    var v = Vec[bool].new()
    v.push(true)
    v.push(false)
    v.push(true)
    v.remove(1)

comptime fn bool_clear_len() -> i64:
    var v = Vec[bool].new()
    v.push(true)
    v.push(false)
    v.clear()
    v.len()

const BOOLS: Vec[bool] = comptime build_bool_vec()
const BOOL_LEN: i64 = comptime bool_len()
const BOOL_HIT: bool = comptime bool_contains_hit()
const BOOL_MISS: bool = comptime bool_contains_miss()
const BOOL_POPPED: bool = comptime bool_pop_val()
const BOOL_POP_LEN: i64 = comptime bool_pop_len()
const BOOL_REMOVED: bool = comptime bool_remove_val()
const BOOL_CLEAR_LEN: i64 = comptime bool_clear_len()

fn main:
    assert(BOOLS.len() == 3)
    assert(BOOLS.get(0) == true)
    assert(BOOLS.get(1) == false)
    assert(BOOLS.get(2) == true)
    assert(BOOL_LEN == 2)
    assert(BOOL_HIT == true)
    assert(BOOL_MISS == false)
    assert(BOOL_POPPED == false)
    assert(BOOL_POP_LEN == 2)
    assert(BOOL_REMOVED == false)
    assert(BOOL_CLEAR_LEN == 0)
    print("ok")
