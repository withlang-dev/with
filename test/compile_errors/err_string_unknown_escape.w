//! expect-error: unknown escape sequence '\u' in string literal

// #929: an escape the decoders don't know is a compile error, never
// silent text — `\u{0}` once produced the literal characters `u{0}`.
fn main:
    let s = "nul:\u{0}"
    print(s)
