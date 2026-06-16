//! expect-error: channel element type must be Send

use std.rc

async fn make_owner() -> Rc[i32]:
    Rc.new(1)

fn main:
    let (_tx, _rx) = chan[Task[Rc[i32]]](1)
