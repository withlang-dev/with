//! expect-check-fail: BTreeMap literal key type must implement Ord

type Key { value: i32 }

fn main:
    let _values: BTreeMap[Key, i32] = [Key { value: 1 }: 10]
