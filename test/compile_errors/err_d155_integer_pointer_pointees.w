//! expect-error: as *const c_char

// D155 (§16.1): a byte pointer is not a C-string pointer when c_char is i8;
// the two interpretations are explicit, and the diagnostic names the cast.
extern fn c_strlen(s: *const c_char) -> u64

fn main:
    let bytes: [1]u8 = [65]
    let p = &raw const bytes[0]
    let n = unsafe { c_strlen(p) }
    print(n)
