//! expect-error: BTreeMap comprehension key type must implement Ord

use std.collections.BTreeMap
type Key { value: i32 }

fn main:
    let _bad: BTreeMap[Key, i32] = [Key { value: x }: x for x in 0..3]
