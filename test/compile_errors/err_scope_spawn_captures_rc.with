//! expect-error: scoped thread worker captures non-ScopedSend value

use std.rc

fn main:
    let local = Rc.new(41)
    scope s =>:
        let handle = s.spawn(() => local.strong_count() as i32)
        handle.join()
