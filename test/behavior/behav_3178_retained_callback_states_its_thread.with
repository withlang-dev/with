//! expect-stdout: -1 42

// #3178 (§16.2b.9, Eric 2026-11-18): a callback the library keeps is called
// after the registering call returns, so the contract says which thread
// calls it.
use c_import("typedef struct box { int (*hook)(int); } box;\nstatic box the_box;\nstatic inline box *box_new(void) { the_box.hook = 0; return &the_box; }\nstatic inline void box_close(box *b) { b->hook = 0; }\nstatic inline void box_set(box *b, int (*f)(int)) { b->hook = f; }\nstatic inline int box_fire(box *b, int x) { return b->hook ? b->hook(x) : -1; }\n")

c contract boxes:
    resource Latch wraps *mut box
        from box_new
        drop box_close
    fn box_set
        callback param 1
        retains param 1 by param 0
        callback_thread registering
    fn box_fire
        lend

fn twice(x: c_int) -> c_int: x * 2

fn main:
    var b = Latch.new().unwrap()
    let before = b.fire(21)
    b.set(twice)
    print(f"{before} {b.fire(21)}")
