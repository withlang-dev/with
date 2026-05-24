//! expect-stdout: ok

comptime fn build_i64_vec() -> Vec[i64]:
    var v = Vec[i64].new()
    v.push(1000000000000)
    v.push(-9223372036854775807)
    v.push(9223372036854775807)
    v

comptime fn i64_len() -> i64:
    var v = Vec[i64].new()
    v.push(100)
    v.push(200)
    v.push(300)
    v.len()

comptime fn i64_contains_hit() -> bool:
    var v = Vec[i64].new()
    v.push(1000000000000)
    v.push(2000000000000)
    v.contains(2000000000000)

comptime fn i64_contains_miss() -> bool:
    var v = Vec[i64].new()
    v.push(1000000000000)
    v.contains(999)

comptime fn i64_pop_val() -> i64:
    var v = Vec[i64].new()
    v.push(100)
    v.push(200)
    v.push(300)
    v.pop()

comptime fn i64_pop_len() -> i64:
    var v = Vec[i64].new()
    v.push(100)
    v.push(200)
    v.push(300)
    let _ = v.pop()
    v.len()

comptime fn i64_remove_val() -> i64:
    var v = Vec[i64].new()
    v.push(111)
    v.push(222)
    v.push(333)
    v.remove(1)

comptime fn i64_clear_len() -> i64:
    var v = Vec[i64].new()
    v.push(1)
    v.push(2)
    v.clear()
    v.len()

const I64S: Vec[i64] = comptime build_i64_vec()
const I64_LEN: i64 = comptime i64_len()
const I64_HIT: bool = comptime i64_contains_hit()
const I64_MISS: bool = comptime i64_contains_miss()
const I64_POPPED: i64 = comptime i64_pop_val()
const I64_POP_LEN: i64 = comptime i64_pop_len()
const I64_REMOVED: i64 = comptime i64_remove_val()
const I64_CLEAR_LEN: i64 = comptime i64_clear_len()

fn main:
    assert(I64S.len() == 3)
    assert(I64S.get(0) == 1000000000000)
    assert(I64S.get(1) == -9223372036854775807)
    assert(I64S.get(2) == 9223372036854775807)
    assert(I64_LEN == 3)
    assert(I64_HIT == true)
    assert(I64_MISS == false)
    assert(I64_POPPED == 300)
    assert(I64_POP_LEN == 2)
    assert(I64_REMOVED == 222)
    assert(I64_CLEAR_LEN == 0)
    print("ok")
