type Box {
    value: i32,
    action: fn(i32) -> i32,
}

comptime fn plus_one(value: i32) -> i32:
    value + 1

comptime fn times_two(value: i32) -> i32:
    value * 2

comptime fn build_box() -> Box:
    var item = Box { value: 10, action: plus_one }
    item.value = 21
    item.action = times_two
    item

const RESULT: i32 = comptime build_box().action(build_box().value)

fn main:
    assert(RESULT == 42)
    print("ok")
