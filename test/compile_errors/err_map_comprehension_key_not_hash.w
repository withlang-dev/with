//! expect-error: HashMap comprehension key type must implement Hash

type Key { value: i32 }

fn main:
    let _bad = [Key { value: x }: x for x in 0..3]
