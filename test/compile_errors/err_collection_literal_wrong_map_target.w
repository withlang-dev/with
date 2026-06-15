//! expect-check-fail: map literal requires HashMap or BTreeMap expected type

fn main:
    let values: Option[i32] = ["x": 1]
