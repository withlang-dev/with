//! expect-stdout: in range: true | empty: 10 -3 | same seed, same draws: true
// #2279: std.random draws the type its use demands. An `i64` bound draws
// an `i64` past the `i32` range, a `u8` parameter draws a `u8`, a typed
// binding names the type, floats are uniform in [lo, hi), and a range
// with hi <= lo is lo. Seeding repeats the sequence.
use std.random

fn byte(b: u8): b

fn draws() -> List[i64]:
    var out: List[i64] = []
    for _ in 0..5: out.push(range(0, 1099511627776))
    out

fn main:
    seed(42)
    let hi: i64 = 1099511627776
    var ok = true
    var past_i32 = false
    for _ in 0..2000:
        let big = range(0, hi)
        if big < 0 or big >= hi: ok = false
        if big > 2147483647: past_i32 = true
        let b = byte(range(97, 123))
        if b < 97 or b >= 123: ok = false
        let s: i8 = range(-100, 100)
        if s < -100 or s >= 100: ok = false
        let u: u16 = range(60000, 65535)
        if u < 60000: ok = false
        let f: f64 = next()
        if f < 0.0 or f >= 1.0: ok = false
        let g = range(-2.5, 2.5)
        if g < -2.5 or g >= 2.5: ok = false
        let h: f32 = range(1.0, 2.0)
        if h < 1.0 or h >= 2.0: ok = false
    let empty_hi: i32 = 10
    let lo_after_hi: i64 = -3
    seed(7)
    let first = draws()
    seed(7)
    let second = draws()
    print(f"in range: {ok and past_i32} | empty: {range(empty_hi, empty_hi)} {range(lo_after_hi, -9)} | same seed, same draws: {first == second}")
