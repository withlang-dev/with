//! expect-error: BTreeMap comprehension key type must implement Ord

type Key { value: i32 }

fn main:
    let _bad: BTreeMap[Key, i32] = [Key { value: x }: x for x in 0..3]
