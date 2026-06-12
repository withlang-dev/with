use c_import("stdlib.h")

type Handle = opaque

type Holder {
    h: *mut Handle,
}

var G: *mut Handle = null

type Raw {
    base: *mut c_void,
}

fn singleton() -> *mut Handle:
    if G != null:
        return G
    // Assign the global directly from the allocation so no scope-bound
    // local is recorded as its view origin (§21.1).
    G = unsafe { malloc(32usize) }.unwrap() as *mut Handle
    let p = G as *mut Raw
    unsafe:
        (*p).base = G as *mut c_void
    G

fn make_holder() -> Holder:
    Holder { h: singleton() }

fn main:
    let h = make_holder()
    assert(h.h == singleton())
