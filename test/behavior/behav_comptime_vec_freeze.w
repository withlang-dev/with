//! expect-stdout: ok

comptime fn build_values() -> Vec[i32]:
    var out = Vec[i32].new()
    out.push(10)
    out.push(20)
    out.push(30)
    out

comptime fn count_values() -> i64:
    var out = Vec[i32].new()
    out.push(1)
    out.push(2)
    out.len()

const VALUES: Vec[i32] = comptime build_values()
const VALUE_COUNT: i64 = comptime count_values()

fn main:
    assert(VALUE_COUNT == 2)
    assert(VALUES.len() == 3)
    assert(VALUES.get(0) == 10)
    assert(VALUES.get(1) == 20)
    assert(VALUES.get(2) == 30)
    print("ok")
