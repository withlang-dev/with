//! expect-stdout: 104 104 104 104 104 104 104 true 65 true false 109 105 1104 200
//! expect-stdout: 0
//! expect-stdout: 104 2

// D207 (§16.1, #3375): `c_char` is a type of its own on every target. What
// stays written without ceremony: it converts to and from every integer
// type with `as` (to `u8` and `i8` keeping the byte), widens into a wider
// signed type, takes a literal from 0 to 127 and an ASCII character
// literal, and computes and compares with another `c_char`. A pointer to it
// converts to a byte pointer with `as`, in safe code.
fn takec(p: *const c_char) -> i32: 0
fn takeu(p: *const u8) -> i32: 0

fn main:
    let p = c"hi".ptr
    let c: c_char = unsafe { *p }
    let b = c as u8
    let s = c as i8
    let back = b as c_char
    let w: i32 = c
    let w64: i64 = c
    let wz: isize = c
    let a: c_char = 5
    let q: c_char = 'A'
    let five: c_char = 5
    let big = 200 as c_char
    let sum = c + a
    let n = c as i32 + 1
    let wide = (c as i32) + 1000
    print(f"{c} {b} {s} {back} {w} {w64} {wz} {a == five} {q} {c == 104} {c < a} {sum} {n} {wide} {big as u8}")
    print(takec(p) + takeu(p as *const u8) + takec(&raw const b as *const c_char))
    let xs: List[c_char] = [104, 105]
    print(f"{xs[0]} {xs.len()}")
