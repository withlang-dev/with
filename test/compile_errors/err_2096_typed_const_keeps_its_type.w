//! expect-error: implicit integer narrowing or sign change from `i64` to `i32`

// D88 (§4.2.1): a `const` with a declared type, or whose initializer has a
// suffixed literal, has that type at every use. (Pinned through an integer
// narrowing since D182 made a float narrowing implicit.)

const WIDE: i64 = 12

fn main:
    let z: i32 = WIDE
    print(f"{z}")
