//! expect-check-fail: type does not support indexed assignment

type Tensor { value: i32 }

impl Tensor:
    fn multi_index(self: &Self, specs: &[IndexSpec], count: i32) -> i32:
        self.value

fn main:
    var t = Tensor { value: 1 }
    t[0, 0] = 2
