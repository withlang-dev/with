//! expect-stdout: ok

comptime fn i32_pop_val() -> i32:
    var v = Vec[i32].new()
    v.push(10)
    v.push(20)
    v.push(30)
    v.pop()

comptime fn i32_pop_remaining() -> Vec[i32]:
    var v = Vec[i32].new()
    v.push(10)
    v.push(20)
    v.push(30)
    let _ = v.pop()
    v

comptime fn i32_remove_first() -> i32:
    var v = Vec[i32].new()
    v.push(10)
    v.push(20)
    v.push(30)
    v.remove(0)

comptime fn i32_remove_middle() -> i32:
    var v = Vec[i32].new()
    v.push(10)
    v.push(20)
    v.push(30)
    v.remove(1)

comptime fn i32_remove_last() -> i32:
    var v = Vec[i32].new()
    v.push(10)
    v.push(20)
    v.push(30)
    v.remove(2)

comptime fn i32_remove_remaining() -> Vec[i32]:
    var v = Vec[i32].new()
    v.push(10)
    v.push(20)
    v.push(30)
    let _ = v.remove(1)
    v

comptime fn i32_clear_len() -> i64:
    var v = Vec[i32].new()
    v.push(10)
    v.push(20)
    v.push(30)
    v.clear()
    v.len()

comptime fn i32_contains_hit() -> bool:
    var v = Vec[i32].new()
    v.push(10)
    v.push(20)
    v.push(30)
    v.contains(20)

comptime fn i32_contains_miss() -> bool:
    var v = Vec[i32].new()
    v.push(10)
    v.push(20)
    v.push(30)
    v.contains(99)

const POP_VAL: i32 = comptime i32_pop_val()
const POP_REM: Vec[i32] = comptime i32_pop_remaining()
const REM_FIRST: i32 = comptime i32_remove_first()
const REM_MID: i32 = comptime i32_remove_middle()
const REM_LAST: i32 = comptime i32_remove_last()
const REM_REM: Vec[i32] = comptime i32_remove_remaining()
const CLR_LEN: i64 = comptime i32_clear_len()
const HAS_20: bool = comptime i32_contains_hit()
const HAS_99: bool = comptime i32_contains_miss()

fn main:
    assert(POP_VAL == 30)
    assert(POP_REM.len() == 2)
    assert(POP_REM.get(0) == 10)
    assert(POP_REM.get(1) == 20)
    assert(REM_FIRST == 10)
    assert(REM_MID == 20)
    assert(REM_LAST == 30)
    assert(REM_REM.len() == 2)
    assert(REM_REM.get(0) == 10)
    assert(REM_REM.get(1) == 30)
    assert(CLR_LEN == 0)
    assert(HAS_20 == true)
    assert(HAS_99 == false)
    print("ok")
