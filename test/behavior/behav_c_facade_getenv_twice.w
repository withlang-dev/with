//! expect-stdout: two values: true true
//! expect-stdout: ok

// An application that wants a value of its own copies it out with
// `to_owned()`: the copy outlives every later change to the environment.
// Holding two views at once is also accepted since D208
// (behav_3127_two_getenv_views); a view dies at a call that rewrites the
// environment (err_c_facade_getenv_view_invalidated).

use c_import("char *getenv(const char *name);\n")

fn main:
    let home = getenv("HOME").map(v => v.to_owned())
    let path = getenv("PATH")
    print(f"two values: {home.is_some()} {path.is_some()}")
    print("ok")
