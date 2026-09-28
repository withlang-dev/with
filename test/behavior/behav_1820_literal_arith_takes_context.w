//! expect-stdout: let 3 250 -3 3
//! expect-stdout: param 3 -3
//! expect-stdout: return 3
//! expect-stdout: element 3 3
//! expect-stdout: field 3
//! expect-stdout: assign 3
//! expect-stdout: global 3 18446744073709551615
//! expect-stdout: peer 5 255
//! expect-stdout: suffixed peer 3
//! expect-stdout: float 3.75 -1.5
//! expect-stdout: range 4

// §4.2.1 rule 1 (#1820): the context type reaches through arithmetic made of
// unsuffixed literals and parentheses, as it reaches a bare literal. Each
// line was "implicit integer narrowing" at the let, or computed in i32 and
// truncated at the other positions.
type S { a: u8 }

let G: u8 = (1 + 2) * 1
let U: u64 = 9223372036854775807 * 2 + 1

fn take(x: u8, y: i8): print(f"param {x} {y}")
fn three() -> u8: 1 + 2

fn main:
    let a: u8 = 1 + 2
    let b: u8 = (200 + (100 - 50)) * 1
    let c: i8 = -(1 + 2)
    let d: u64 = 1 + 2
    print(f"let {a} {b} {c} {d}")
    take(1 + 2, -(1 + 2))
    print(f"return {three()}")
    let arr: [2]u8 = [0, 1 + 2]
    let tup: (u8, u8) = (0, 1 + 2)
    print(f"element {arr[1]} {tup.1}")
    let s = S { a: 1 + 2 }
    print(f"field {s.a}")
    var x: u8 = 0
    x = 1 + 2
    print(f"assign {x}")
    print(f"global {G} {U}")
    // Rule 3: the typed peer gives the literal arithmetic its type.
    let y: u8 = 2
    let big: u8 = 250
    print(f"peer {y + (1 + 2)} {big + (2 + 3)}")
    // A suffixed literal is a typed peer: 1 takes u16, the u16 sum widens.
    let z: u32 = 1 + 2u16
    print(f"suffixed peer {z}")
    let f: f32 = 1.5 + 2.25
    let g: f32 = -1.5
    print(f"float {f} {g}")
    // A range's literal bound takes its peer bound's type (rule 3).
    let n: i64 = 4
    var count: i64 = 0
    for i in 0..n:
        count = count + 1
    print(f"range {count}")
