//! expect-stdout: ok

type ComptimeGenericMut { count: i32 }

comptime fn ComptimeGenericMut.produce[T](mut self: Self, value: T) -> T:
    self.count += 1
    value

comptime fn ComptimeGenericMut.mark(mut self: Self):
    self.count += 1

comptime fn comptime_unit() -> Unit:
    return

comptime fn unit_count() -> i32:
    var value = ComptimeGenericMut { count: 0 }
    value |> produce(comptime_unit()) |> mark()
    value.count

comptime fn bool_result() -> bool:
    var value = ComptimeGenericMut { count: 0 }
    let result = value |> produce(true)
    result and value.count == 1

comptime fn direct_count() -> i32:
    var value = ComptimeGenericMut { count: 0 }
    value.mark()
    value.count

const UNIT_COUNT: i32 = comptime unit_count()
const BOOL_RESULT: bool = comptime bool_result()
const DIRECT_COUNT: i32 = comptime direct_count()

fn main:
    assert(UNIT_COUNT == 2)
    assert(BOOL_RESULT)
    assert(DIRECT_COUNT == 1)
    print("ok")
