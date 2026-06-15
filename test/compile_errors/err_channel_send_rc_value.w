//! expect-error: channel send requires Send value

use std.rc

fn main:
    let local = Rc.new(1)
    send(0, local)
