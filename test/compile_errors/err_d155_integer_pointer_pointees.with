//! expect-error: as *const c_char

// D155 (§16.1): a pointer to one integer type is not a pointer to another:
// a byte pointer is not a C-string pointer; the two interpretations are
// explicit, and the diagnostic names the cast. c_char is the target's
// (i8 on x86_64 and darwin, u8 on linux-aarch64), so one of the two calls
// below is the mismatch on every target.
extern fn c_strlen(s: *const c_char) -> u64

fn main:
    let unsigned_bytes: [1]u8 = [65]
    let signed_bytes: [1]i8 = [65]
    let pu = &raw const unsigned_bytes[0]
    let ps = &raw const signed_bytes[0]
    let n = unsafe { c_strlen(pu) + c_strlen(ps) }
    print(n)
