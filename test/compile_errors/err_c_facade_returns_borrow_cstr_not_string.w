//! expect-check-fail: fn 'note_id' returns i32, not a C string ('char *'); 'returns borrow CStr' describes a NUL-terminated foreign string (§16.2b.8)

// D51 stage 7 (ruling §41, §61): `returns borrow CStr` is verified against
// the declaration — the operation must return a C string pointer.
use c_import("../behavior/c_facade_text.h")

c facade notes:
    resource Note wraps *mut note
        from note_new
        drop note_free
    fn note_id
        returns borrow CStr from param 0

fn main:
    print("unreached")
