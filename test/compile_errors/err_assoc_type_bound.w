//! expect-error: does not satisfy bound

type NoEqType { x: i32 }

trait Container =
    type Item: Eq
    fn get(self: &Self) -> i32

impl Container for NoEqType =
    type Item = NoEqType
    fn get(self: NoEqType) -> i32:
        self.x

fn main:
    let n = NoEqType { x: 42 }
    print(int_to_string(n.get()))
