//! expect-stdout: ok

comptime fn build_values() -> List[i32]:
    var out = List[i32].new()
    out.push(10)
    out.push(20)
    out.push(30)
    out

comptime fn count_values() -> i64:
    var out = List[i32].new()
    out.push(1)
    out.push(2)
    out.len()

const VALUES: List[i32] = comptime build_values()
const VALUE_COUNT: i64 = comptime count_values()

fn main:
    assert(VALUE_COUNT == 2)
    assert(VALUES.len() == 3)
    assert(VALUES[0] == 10)
    assert(VALUES[1] == 20)
    assert(VALUES[2] == 30)
    print("ok")
