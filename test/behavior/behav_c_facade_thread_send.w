//! expect-stdout: ok

// D51 stage 9 (ruling §48-§50, spec §16.2b.10): a resource is bound to the
// thread that created it unless its facade grants `send` (with
// `drop_any_thread`, since With does not marshal destruction back) — then
// it moves into an OS thread. `share` makes shared views usable across
// threads: an `Arc` of the resource crosses when it is `send share`.
// Neither is inferred from the representation. (A `move` closure's
// environment still lives in the caller's frame — D62 is not implemented
// yet — so the resource is destroyed when that frame ends, and a capture
// consumed inside the closure is dropped twice; the closures here read
// their captures, and the close is asserted after the frame.)
use c_import("c_facade_callbacks.h")
use std.thread
use std.rc

c facade dbc:
    resource Database wraps *mut db
        from db_new
        drop db_close
        thread send drop_any_thread
    resource Shared wraps *mut db
        from db_new
        drop db_close
        thread send share drop_any_thread
    fn db_id
        of Database
        lend
    fn db_total
        of Shared
        lend

fn main:
    let l = log_new()
    if true:
        let d = Database.new(l, 1).unwrap()
        let h = spawn_os(move () => d.id())
        assert(join(h) == 1)
    assert(log_len(l) == 1 and log_at(l, 0) == 2001)
    if true:
        let s = Arc.new(Shared.new(l, 2).unwrap())
        let s2 = s.clone()
        let h2 = spawn_os(move () => s2.total() + 5)
        assert(join(h2) == 5)
        assert(log_len(l) == 1)
    assert(log_len(l) == 2 and log_at(l, 1) == 2002)
    log_free(l)
    print("ok")
