//! expect-error: derive Default for generic structs is not implemented yet

@[derive(Default)]
type Boxed[T] { value: T }

fn main:
    let _ = 0
