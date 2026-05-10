//! expect-error: derive SoA for generic structs is not implemented yet

@[derive(SoA)]
type Column[T] { value: T }

fn main:
    let _ = 0
