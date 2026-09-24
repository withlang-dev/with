//! expect-check-fail: 'callback consumes' is not modeled yet; a callback receives its userdata as a borrow for the callback's scope

// D51 stage 9 (ruling §46, spec §16.2b.9): a callback receiving ownership
// is stated, never inferred — and not yet modeled: the clause parses and is
// refused, so no facade quietly gets the borrow it did not state.
use c_import("../behavior/c_facade_callbacks.h")

c facade dbc:
    resource Database wraps *mut db
        from db_new
        drop db_close
    fn db_exec
        callback param 1 userdata param 2
        callback consumes param 1

fn main:
    print("ok")
