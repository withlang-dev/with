//! expect-error: List.join joins str elements, and this List holds `i32`

// List.join concatenates str elements; a List[i32] was accepted and read each
// pair of ints as a str's {ptr, len} (printed nothing, or crashed in memcpy).
fn main:
    let v: List[i32] = [5, 3]
    print(v.join(" "))
