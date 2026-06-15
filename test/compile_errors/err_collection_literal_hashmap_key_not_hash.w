//! expect-check-fail: HashMap literal key type must implement Hash

type Key { value: i32 }

fn main:
    let values = [Key { value: 1 }: 10]
