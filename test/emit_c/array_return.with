//! expect-stdout: 9 3 8

// #1775: a function returning an array crosses by value. The C backend
// returned a pointer to the callee's own dead local (`uint16_t* arr()`
// returning `_0`) and assigned the result to an array local, which no C
// compiler accepts ("array type is not assignable").
fn arr() -> [u16; 2]: [7u16, 9u16]
fn grid() -> [2][2]i32: [[1, 2], [3, 4]]
fn pick(xs: [3]i64) -> [3]i64: xs

fn main:
    let a = arr()
    let g = grid()
    let p = pick([6, 7, 8])
    print(f"{a[1]} {g[1][0]} {p[2]}")
