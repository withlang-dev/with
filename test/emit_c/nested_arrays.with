//! expect-stdout: 3 2

// Nested array literals in a function body: a row is a C array, which no
// initializer list takes by name (the C backend emitted `{_22, _44}`).
fn main:
    let t = [[1, 2], [3, 4]]
    let u: [2][3]u8 = [[1u8, 2u8, 3u8], [4u8, 5u8, 6u8]]
    print(f"{t[1][0]} {u[0][1]}")
