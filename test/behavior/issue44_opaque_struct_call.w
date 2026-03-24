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
    let raw = malloc(32usize).unwrap()
    let p = raw as *mut Raw
    unsafe:
        (*p).base = raw
    G = p as *mut Handle
    G

fn make_holder() -> Holder:
    Holder { h: singleton() }

fn main:
    let h = make_holder()
    assert(h.h == singleton())
