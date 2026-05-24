//! expect-stdout: ok

comptime fn build_u8_vec() -> Vec[u8]:
    var v = Vec[u8].new()
    v.push(10)
    v.push(20)
    v.push(30)
    v

comptime fn u8_len() -> i64:
    var v = Vec[u8].new()
    v.push(1)
    v.push(2)
    v.push(3)
    v.len()

comptime fn u8_contains_hit() -> bool:
    var v = Vec[u8].new()
    v.push(10)
    v.push(20)
    v.contains(20)

comptime fn u8_contains_miss() -> bool:
    var v = Vec[u8].new()
    v.push(10)
    v.push(20)
    v.contains(99)

comptime fn u8_pop_val() -> u8:
    var v = Vec[u8].new()
    v.push(10)
    v.push(20)
    v.push(30)
    v.pop()

comptime fn u8_pop_len() -> i64:
    var v = Vec[u8].new()
    v.push(10)
    v.push(20)
    v.push(30)
    let _ = v.pop()
    v.len()

comptime fn u8_remove_val() -> u8:
    var v = Vec[u8].new()
    v.push(10)
    v.push(20)
    v.push(30)
    v.remove(1)

comptime fn u8_remove_len() -> i64:
    var v = Vec[u8].new()
    v.push(10)
    v.push(20)
    v.push(30)
    let _ = v.remove(1)
    v.len()

comptime fn u8_clear_len() -> i64:
    var v = Vec[u8].new()
    v.push(10)
    v.push(20)
    v.clear()
    v.len()

comptime fn u8_boundary() -> Vec[u8]:
    var v = Vec[u8].new()
    v.push(0)
    v.push(127)
    v.push(255)
    v

const BASIC: Vec[u8] = comptime build_u8_vec()
const LEN: i64 = comptime u8_len()
const HIT: bool = comptime u8_contains_hit()
const MISS: bool = comptime u8_contains_miss()
const POPPED: u8 = comptime u8_pop_val()
const POP_LEN: i64 = comptime u8_pop_len()
const REMOVED: u8 = comptime u8_remove_val()
const REMOVE_LEN: i64 = comptime u8_remove_len()
const CLEAR_LEN: i64 = comptime u8_clear_len()
const BOUNDARY: Vec[u8] = comptime u8_boundary()

fn main:
    assert(BASIC.len() == 3)
    assert(BASIC.get(0) == 10)
    assert(BASIC.get(1) == 20)
    assert(BASIC.get(2) == 30)
    assert(LEN == 3)
    assert(HIT == true)
    assert(MISS == false)
    assert(POPPED == 30)
    assert(POP_LEN == 2)
    assert(REMOVED == 20)
    assert(REMOVE_LEN == 2)
    assert(CLEAR_LEN == 0)
    assert(BOUNDARY.len() == 3)
    assert(BOUNDARY.get(0) == 0)
    assert(BOUNDARY.get(1) == 127)
    assert(BOUNDARY.get(2) == 255)
    print("ok")
