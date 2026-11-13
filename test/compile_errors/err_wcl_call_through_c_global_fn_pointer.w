//! expect-check-fail: call to unsafe function pointer requires unsafe context

// §31.4: a call through a function pointer is raw. A C global that holds
// one has the unsafe function-pointer type, so reading it (safe here: the
// contract says the library runs no threads) does not make calling C
// through it safe.
use c_import("typedef void (*hook_fn)(void *p);
extern hook_fn lib_hook;
")

c contract lib:
    runs no threads

fn main:
    match lib_hook:
        Some(f) => f(null)
        None => print("none")
