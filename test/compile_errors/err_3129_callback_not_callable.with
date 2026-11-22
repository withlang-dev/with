//! expect-check-fail: 'callback param 3' names
//! expect-check-fail: = help: after 'callback' name the function-pointer parameter: 'callback param N userdata param M'

// #3129 (§16.2b.9): `callback param` names a function-pointer parameter.
use c_import("../behavior/c_facade_callbacks.h")

c contract dbc:
    resource Database wraps *mut db
        from db_new
        drop db_close
    fn db_exec
        callback param 3 userdata param 2

fn main:
    print("unreachable")
