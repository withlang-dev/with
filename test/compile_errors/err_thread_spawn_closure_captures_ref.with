//! expect-check-fail: escaping closure cannot capture ephemeral references

use std.thread

fn bad:
    let x = 42
    let r = &x
    let handle = spawn_os(() => *r)
    let _ = join(handle)
