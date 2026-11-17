//! expect-check-fail: which is not a 'void *'; a callback's userdata is the untyped pointer C hands back to it
//! expect-check-fail: = help: after 'userdata' name the 'void *' parameter C passes back to the callback

// #3129 (§16.2b.9): a callback's userdata is the `void *` parameter.
use c_import("typedef void (*cb_fn)(void *ud);\nstatic inline void each(cb_fn cb, int n) { cb(0); }\n")

c contract eachs:
    fn each
        callback param cb userdata param n

fn main:
    print("unreachable")
