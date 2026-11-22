//! expect-stdout: ok

// §16.12: sizeof/alignof take any type. A raw pointer type argument
// (`*mut T`, `*const T`) in expression position parsed as a dereference of
// `mut` and failed ("expected expression"); c_import emits it for C's
// `sizeof(PVOID)` (winnt.h's TOKEN_INTEGRITY_LEVEL_MAX_SIZE, #1396).

fn main:
    assert(sizeof[*mut c_void]() == 8)
    assert(alignof[*const u8]() == 8)
    let words = (sizeof[*mut c_void]() + sizeof[*const i32]()) / 8
    assert(words == 2)
    let bits: u64 = unsafe { transmute[u64](0 as *mut u8) }
    assert(bits == 0)
    let p: *mut u8 = unsafe { transmute[*mut u8](16 as u64) }
    assert(p as u64 == 16)
    print("ok")
