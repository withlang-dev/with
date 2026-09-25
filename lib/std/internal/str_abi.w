// Internal stdlib bridge helpers for byte-oriented routines.
//
// Use this only when stdlib code must pass a str's bytes to a raw pointer API.
// A str is an aggregate value; casting the str itself to *const u8 points at
// the aggregate, not at the payload.

extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8) -> Unit

pub unsafe fn str_copy_bytes(s: &str) -> *mut u8:
    let out = with_alloc(s.len() + 1)
    let data = **(&s as *const *const *const u8)
    var i: i64 = 0
    while i < s.len():
        *((out as i64 + i) as *mut u8) = data[i]
        i = i + 1
    *((out as i64 + s.len()) as *mut u8) = 0
    out

pub unsafe fn str_free_bytes(p: *mut u8):
    with_free(p)
