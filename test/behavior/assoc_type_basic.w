//! expect-stdout: ok

trait Container =
    type Item
    fn get(self: Self) -> i32

type IntBox { value: i32 }

impl Container for IntBox =
    type Item = i32
    fn get(self: IntBox) -> i32:
        self.value

fn main:
    let b = IntBox { value: 42 }
    assert(b.get() == 42)
    print("ok")
