//! expect-error: Vec.join joins str elements, and this Vec holds `i32`

// Vec.join concatenates str elements; a Vec[i32] was accepted and read each
// pair of ints as a str's {ptr, len} (printed nothing, or crashed in memcpy).
fn main:
    let v: Vec[i32] = [5, 3]
    print(v.join(" "))
