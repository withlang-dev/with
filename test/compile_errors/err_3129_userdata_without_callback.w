//! expect-check-fail: a userdata given with no callback to receive it
//! expect-check-fail: = help: pass None for the userdata too, or pass the callback

// #3129 (§16.2b.9): the callback and its userdata are one pairing; an absent
// callback takes its userdata with it.
use c_import("typedef void (*cb_fn)(void *ud);\nstatic inline void each(cb_fn cb, void *ud) { if (cb) cb(ud); }\n")

c contract eachs:
    fn each
        callback param cb userdata param ud
        nullable param cb

fn main:
    var n = 0
    each(None, n)
    print(n)
