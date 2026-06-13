//! expect-check-fail: receiver must be `mut self: Self` for MultiIndexMut

type Tensor { value: i32 }

impl MultiIndex[i32] for Tensor:
    fn multi_index(self: &Self, specs: &[IndexSpec], count: i32) -> i32:
        self.value

impl Tensor:
    fn multi_index_set(self: &Self, specs: &[IndexSpec], count: i32, value: i32) -> Unit:
        let _ = value

fn main:
    var t = Tensor { value: 1 }
    t[0, 0] = 2
