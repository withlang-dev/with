//! env: WITH_RT_IN_UNIT=1
//! expect-check-fail: escaping closure cannot capture ephemeral references

// D30: compiled in-unit, the runtime's with_thread_spawn replaces
// std.thread's `@[effect(fn_ptr: escape_value, ctx: escape_value)] extern
// fn with_thread_spawn`, and takes that declared contract: the thread keeps
// the closure, so one holding a view of this frame cannot be spawned.
// Inferred from the runtime's body alone (a raw pointer's retention is
// never inferred), the closure escaped unrefused. The lane twin of
// err_thread_spawn_closure_captures_ref.
use std.thread

fn bad:
    let x = 42
    let r = &x
    let handle = spawn_os(() => *r)
    let _ = join(handle)

fn main:
    bad()
