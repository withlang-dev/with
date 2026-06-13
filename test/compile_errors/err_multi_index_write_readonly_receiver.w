//! expect-check-fail: cannot assign through a read-only place

type Tensor { value: i32 }

impl MultiIndex[i32] for Tensor:
    fn multi_index(self: &Self, specs: &[IndexSpec], count: i32) -> i32:
        self.value

impl MultiIndexMut[i32] for Tensor:
    fn multi_index_set(mut self: Self, specs: &[IndexSpec], count: i32, value: i32) -> Unit:
        self.value = value

fn overwrite(t: &Tensor):
    t[0, 0] = 2

fn main:
    let t = Tensor { value: 1 }
    overwrite(&t)
