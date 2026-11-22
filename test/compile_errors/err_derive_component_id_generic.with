//! expect-error: derive ComponentId requires a concrete struct

use std.component

@[derive(ComponentId)]
type ComponentBox[T] {
    value: T,
}

fn main:
    let _id = ComponentBox[i32].component_id()
