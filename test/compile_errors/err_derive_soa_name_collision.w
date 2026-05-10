//! expect-error: derive SoA target type 'ItemSoA' already exists

type ItemSoA { value: Vec[i32] }

@[derive(SoA)]
type Item { value: i32 }

fn main:
    let _ = 0
