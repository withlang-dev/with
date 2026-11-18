//! expect-check-fail: fn 'box_set': 'callback param 1' is retained, and the contract does not say which thread calls it (§16.2b.9)
//! expect-check-fail: add 'callback_thread any' when the library may call it from any thread, or 'callback_thread registering' when it calls it only on the thread that registered it

// #3178 (§16.2b.9, Eric 2026-11-18): "on the calling thread" is a safe
// default only while the call is running. A kept callback states its thread.
use c_import("typedef struct box { int (*hook)(int); } box;\nstatic box the_box;\nstatic inline box *box_new(void) { the_box.hook = 0; return &the_box; }\nstatic inline void box_close(box *b) { b->hook = 0; }\nstatic inline void box_set(box *b, int (*f)(int)) { b->hook = f; }\nstatic inline int box_fire(box *b, int x) { return b->hook ? b->hook(x) : -1; }\n")

c contract boxes:
    resource Latch wraps *mut box
        from box_new
        drop box_close
    fn box_set
        callback param 1
        retains param 1 by param 0
    fn box_fire
        lend

fn twice(x: c_int) -> c_int: x * 2

fn main:
    var b = Latch.new().unwrap()
    b.set(twice)
    print(b.fire(21))
