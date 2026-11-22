//! expect-stdout: ok

use std.component

@[derive(ComponentId)]
type Position {
    x: i32,
    y: i32,
}

@[derive(ComponentId)]
type Velocity {
    dx: i32,
    dy: i32,
}

const POSITION_HAS_COMPONENT_ID: bool = comptime Position.implements(ComponentId)
const VELOCITY_HAS_COMPONENT_ID: bool = comptime Velocity.implements(ComponentId)

fn main:
    assert(POSITION_HAS_COMPONENT_ID)
    assert(VELOCITY_HAS_COMPONENT_ID)

    let pos_id = Position.component_id()
    let vel_id = Velocity.component_id()
    assert(pos_id == 1156229881)
    assert(vel_id == 1019112964)
    assert(pos_id != vel_id)

    print("ok")
