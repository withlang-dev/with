//! expect-stdout: ok

type FILE = opaque

fn is_null_file(p: *mut FILE) -> bool:
    p == null

unsafe fn accepts_file(p: *mut FILE) -> bool:
    p == null

fn main:
    let p: *mut FILE = null
    let q: *const FILE = null
    assert(is_null_file(p))
    assert(unsafe { accepts_file(p) })
    assert(q == null)
    print("ok")
