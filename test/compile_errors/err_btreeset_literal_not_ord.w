//! expect-check-fail: BTreeSet literal element type must implement Ord

type Key { value: i32 }

fn main:
    let _values: BTreeSet[Key] = [Key { value: 1 }]
