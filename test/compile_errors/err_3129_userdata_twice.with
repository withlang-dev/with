//! expect-check-fail: is given its userdata twice
//! expect-check-fail: = help: delete one of the two 'callback param … userdata param …' clauses

// #3129 (§16.2b.9): one callback has one userdata pairing.
use c_import("typedef void (*cb_fn)(void *ud);\nstatic inline void each(cb_fn cb, void *ud) { cb(ud); }\n")

c contract eachs:
    fn each
        callback param cb userdata param ud
        callback param cb userdata param ud

fn main:
    print("unreachable")
