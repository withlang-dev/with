//! expect-stdout: 1 2 3
//! expect-stdout: 1 3 1
//! expect-stdout: 7 8 9
//! expect-stdout: 5 6
//! expect-stdout: 4 5 6
//! expect-stdout: 6

// #1367 (§9.7): a slice pattern over a fixed-size array is decided at compile
// time, so one that always matches is irrefutable: `let` needs no else. Rest
// forms (a rest binds the remaining count), a nested array inside a tuple, a
// struct field, `var`, and a parameter pattern.
type Grid { row: [3]i32 }

fn sum3([a, b, c]: [3]i32) -> i32: a + b + c

fn main:
    let arr = [1, 2, 3]
    let [a, b, c] = arr
    print(f"{a} {b} {c}")
    let [first, ..mid, last] = arr
    print(f"{first} {last} {mid}")
    let (x, [y, z]) = (7, [8, 9])
    print(f"{x} {y} {z}")
    let g = Grid { row: [4, 5, 6] }
    let Grid { row: [_, p, q] } = g
    print(f"{p} {q}")
    var [m, ..] = [4, 5, 6]
    m = m + 0
    let [_, n, o] = [0, 5, 6]
    print(f"{m} {n} {o}")
    print(f"{sum3(arr)}")
