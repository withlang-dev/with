//! expect-error: E0702

use std.sync

fn main:
    let barrier = Barrier.new(2)
    no_suspend:
        let _ = barrier.wait()
