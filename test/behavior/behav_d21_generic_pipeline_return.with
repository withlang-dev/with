//! expect-stdout: ok

type GenericMut { count: i32 }

fn GenericMut.produce[T](mut self: Self, value: T) -> T:
    self.count += 1
    value

impl GenericMut:
    mut fn mark(): self.count += 1

fn unit_value() -> Unit:
    return

fn main:
    var unit_mut = GenericMut { count: 0 }
    unit_mut |> produce(unit_value()) |> mark()
    assert(unit_mut.count == 2)

    var bool_mut = GenericMut { count: 0 }
    let status = bool_mut |> produce(true)
    assert(status)
    assert(bool_mut.count == 1)
    print("ok")
