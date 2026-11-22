//! expect-stdout: 1 2 3
//! expect-stdout: 1 3 1
//! expect-stdout: 7 8 9
//! expect-stdout: 5 6
//! expect-stdout: 4 5 6
//! expect-stdout: 6

// #1367 (§9.7): a slice pattern over a fixed-size array is decided at compile
// time, so one that always matches is irrefutable: `let` needs no else. Rest
// forms (D115: a rest names the remaining elements), a nested array inside a tuple, a
// struct field, `var`, and a parameter pattern. Brackets make a List (D113),
// so each array here is demanded: by `sum3`'s parameter, an annotation, or a
// field.
type Grid { row: [i32; 3] }

fn sum3([a, b, c]: [i32; 3]): a + b + c

fn main:
    let arr = [1, 2, 3]
    let [a, b, c] = arr
    print(f"{a} {b} {c}")
    let [first, ..mid, last] = arr
    print(f"{first} {last} {mid.len()}")
    let pair: (i32, [i32; 2]) = (7, [8, 9])
    let (x, [y, z]) = pair
    print(f"{x} {y} {z}")
    let g = Grid { row: [4, 5, 6] }
    let Grid { row: [_, p, q] } = g
    print(f"{p} {q}")
    let four: [i32; 3] = [4, 5, 6]
    var [m, ..] = move four
    m = m + 0
    let six: [i32; 3] = [0, 5, 6]
    let [_, n, o] = six
    print(f"{m} {n} {o}")
    print(f"{sum3(arr)}")
