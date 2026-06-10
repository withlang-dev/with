// Internal stdlib bridge helpers for byte-oriented routines.
//
// Use this only when stdlib code must pass a str's bytes to a raw pointer API.
// A str is an aggregate value; casting the str itself to *const u8 points at
// the aggregate, not at the payload.

extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8) -> void

pub unsafe fn str_copy_bytes(s: str) -> *mut u8:
    let out = with_alloc(s.len() + 1)
    var i: i64 = 0
    while i < s.len():
        *((out as i64 + i) as *mut u8) = s.byte_at(i) as u8
        i = i + 1
    *((out as i64 + s.len()) as *mut u8) = 0
    out

pub unsafe fn str_free_bytes(p: *mut u8) -> void:
    with_free(p)
