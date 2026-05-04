//! expect-stdout: 42

trait Container =
    type Item
    fn get(self: &Self) -> Self.Item

type Box32 { value: i32 }

impl Container for Box32 =
    type Item = i32
    fn get(self: Box32) -> i32:
        self.value

fn extract[T: Container](c: T) -> T.Item:
    c.get()

fn main:
    let b = Box32 { value: 42 }
    let result = b.get()
    print(int_to_string(result))
