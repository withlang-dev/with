//! expect-error: thread.spawn_os captures non-Send value

use std.rc
use std.thread

fn main:
    let local = Rc.new(41)
    let handle = spawn_os(() => local.strong_count() as i32)
    let _ = join(handle)
