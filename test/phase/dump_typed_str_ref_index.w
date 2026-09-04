//! args: --dump-typed
//! expect-check-stdout: bind byte: u8
//! expect-check-stdout-not: bind byte: <error>

fn first_byte(text: &str) -> i32:
    let byte = text[0]
    byte

// #1017: the element of a str is its byte, u8 (it was tabled as i32, byte_at's
// return type); returning it as i32 is the ordinary lossless widening.
