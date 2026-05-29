//! expect-check-fail: multi-dimensional index may contain at most one ellipsis

type Tensor { value: i32 }

impl Tensor:
    fn multi_index(self: &Self, specs: &[IndexSpec], count: i32) -> i32:
        self.value

fn main:
    let t = Tensor { value: 1 }
    let _ = t[..., ...]
