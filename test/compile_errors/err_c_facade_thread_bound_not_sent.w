//! expect-check-fail: thread.spawn_os captures non-Send value `d`

// D51 stage 9 (ruling §48, spec §16.2b.10): a modeled resource is bound to
// its creating thread by default; moving it into an OS thread is refused,
// and the note names the facade's thread clause to state. Twin:
// behav_c_facade_thread_send.
use c_import("../behavior/c_facade_callbacks.h")
use std.thread

c facade dbc:
    resource Database wraps *mut db
        from db_new
        drop db_close
    fn db_id
        lend

fn main:
    let l = log_new()
    let d = Database.new(l, 1).unwrap()
    let h = spawn_os(move () => { let mine = d; mine.id() })
    print(f"{join(h)}")
