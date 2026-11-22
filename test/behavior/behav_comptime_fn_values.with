comptime fn inc(value: i32) -> i32:
    value + 1

comptime fn double(value: i32) -> i32:
    value * 2

comptime fn apply(f: fn(i32) -> i32, value: i32) -> i32:
    f(value)

type Runner {
    call: fn(i32) -> i32,
}

comptime fn apply_field(runner: Runner, value: i32) -> i32:
    runner.call(value)

const DIRECT: i32 = comptime apply(inc, 41)
const FIELD: i32 = comptime apply_field(Runner { call: double }, 21)

fn main:
    assert(DIRECT == 42)
    assert(FIELD == 42)
    print("ok")
