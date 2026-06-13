//! expect-check-fail: missing multi_index_set method required by MultiIndexMut

type Tensor { value: i32 }

impl Tensor:
    fn multi_index(self: &Self, specs: &[IndexSpec], count: i32) -> i32:
        self.value

fn main:
    var t = Tensor { value: 1 }
    t[0, 0] = 2
