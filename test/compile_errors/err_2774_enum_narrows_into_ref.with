//! expect-error: wrong argument type in call to 'small'
// #2774 (§4.2.6): an enum converts as its representation type does, so
// an `i32` enum into a `&u8` parameter is an implicit narrowing, refused
// as a plain `i32` there is. It was accepted and read the enum's first byte.
enum K: i32:
    A = 300

fn small(k: &u8) -> u8: k

fn main:
    print(small(K.A))
