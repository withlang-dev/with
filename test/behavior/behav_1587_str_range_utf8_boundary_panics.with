//! expect-exit: 134
//! expect-stderr: string slice inside a UTF-8 character

// D71 (§4.8a): offsets are byte offsets; one that falls inside a UTF-8
// character panics. `é` is two bytes, so byte 2 is inside it.
fn main:
    let s = "héllo"
    let n = 2
    print(s[..n])
