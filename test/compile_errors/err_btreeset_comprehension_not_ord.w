//! expect-error: BTreeSet comprehension element type must implement Ord

type Key { value: i32 }

fn main:
    let _bad: BTreeSet[Key] = [Key { value: x } for x in 0..3]
