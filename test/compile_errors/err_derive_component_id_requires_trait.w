//! expect-error: unknown trait

@[derive(ComponentId)]
type Position {
    x: i32,
    y: i32,
}

fn main:
    let _id = Position.component_id()
