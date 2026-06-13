//! expect-check-fail: missing multi_index method required by MultiIndex

type Tensor { value: i32 }

fn main:
    let t = Tensor { value: 1 }
    let _ = t[0, 0]
