//! expect-check-fail: count parameter must be `i32`

use std.collections.IndexSpec
type Tensor { value: i32 }

impl Tensor:
    fn multi_index(self: &Self, specs: &[IndexSpec], count: i64) -> i32:
        self.value

fn main:
    let t = Tensor { value: 1 }
    let _ = t[0, 0]
