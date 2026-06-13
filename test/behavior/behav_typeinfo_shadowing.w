//! expect-stdout: ok

type TypeInfo { value: i32 }

fn TypeInfo.new(value: i32) -> TypeInfo:
    TypeInfo { value }

fn TypeInfo.fields(self: &Self) -> i32:
    self.value + 1

fn main:
    let info = TypeInfo.new(41)
    assert(info.fields() == 42)
    print("ok")
