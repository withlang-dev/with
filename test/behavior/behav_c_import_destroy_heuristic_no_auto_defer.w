//! expect-stdout: ok

// #357 regression (BDFL ruling #16): the `*_destroy` name heuristic must not
// auto-insert scope-local cleanup. The heuristic auto-defer pipeline was
// removed (commit 1373e453); the compiler does not insert `defer
// widget_destroy(w)` for C resources.
//
// `widget_create` returns a resource pointer and `widget_destroy` is its
// name-matched destructor. The handle is created in `use_and_leave` and leaves
// scope when that function returns. The removed heuristic auto-defer would
// have inserted `widget_destroy(w)` at scope end, flipping the caller-owned
// `destroyed` flag to 1. With the heuristic gone, the flag stays 0; cleanup
// only happens when the programmer calls widget_destroy explicitly (proven
// below).

use c_import("typedef struct Widget { int id; int destroyed; } Widget;\nstatic inline Widget *widget_create(Widget *storage) { storage->id = 7; storage->destroyed = 0; return storage; }\nstatic inline int widget_id(Widget *w) { return w->id; }\nstatic inline void widget_destroy(Widget *w) { w->destroyed = 1; }\n", no_methods: true)

unsafe fn use_and_leave(storage: *mut Widget) -> i32:
    let w = widget_create(storage)
    return widget_id(w)

fn main:
    var storage = Widget { id: 0, destroyed: 0 }
    let id = unsafe { use_and_leave(&raw mut storage) }
    // After use_and_leave returns, its raw Widget* handle has left scope. No
    // auto-defer means widget_destroy never ran on it.
    let after_scope = storage.destroyed
    // Explicit cleanup is the programmer's responsibility and still works.
    unsafe:
        widget_destroy(&raw mut storage)
    let after_explicit = storage.destroyed
    if id == 7 and after_scope == 0 and after_explicit == 1:
        print("ok")
    else:
        print("bad")
