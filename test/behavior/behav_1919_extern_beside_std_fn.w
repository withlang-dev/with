//! expect-stdout: -1 -1

// #1919: a module's own `extern fn unlink` binds its own calls even when the
// program imports std.libc, whose `pub fn unlink` has the same name. The
// flat merge dropped the extern for the std fn, and the owner's call became
// "'unlink' requires an explicit import (§18.1)". This module's `unlink` is
// std.libc's.
use extern_unlink_owner
use std.libc

fn main:
    let owned = extern_owner_remove(c"/nonexistent/with-1919-a".ptr)
    let imported = unlink(c"/nonexistent/with-1919-b".ptr as *const i8)
    print(f"{owned} {imported}")
