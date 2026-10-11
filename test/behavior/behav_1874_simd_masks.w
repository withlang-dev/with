//! expect-stdout: build true false true true | splat true
//! expect-stdout: combine false false true false | true false true true | true true false true
//! expect-stdout: not false true false false | cast true true
//! expect-stdout: select 1 20 3 4 | range 2 3
//! expect-stdout: left 2 4 6 8 | 3 7 9 | 15 1 | 1 2 3 4
//! expect-stdout: m128 true false

// §4.3d (D80, #1874): masks construct, splat, index as bools, combine with
// `& | ^` (a bool operand broadcasting), negate with `not`, and convert
// width with `as`; `m.select(a, b)` picks lanes; a scalar broadcasts on
// either side of every lane-wise operator; 128-bit lanes compare.
fn show(m: m32x4) -> str: f"{m[0]} {m[1]} {m[2]} {m[3]}"

fn main:
    let m = m32x4(true, false, true, true)
    let all_on = m32x4.splat(true)
    print(f"build {show(m)} | splat {all_on.all()}")
    let n = m32x4(false, true, true, false)
    let both = m & n
    let either = m | false
    let differ = m ^ n
    print(f"combine {show(both)} | {show(either)} | {show(differ)}")
    let narrow = m as Mask[4, 8]
    let wide = all_on as Mask[4, 64]
    print(f"not {show(not m)} | cast {narrow.any()} {wide.all()}")

    let a = i32x4(1, 2, 3, 4)
    let b = i32x4(10, 20, 30, 40)
    let picked = m.select(a, b)
    let inside = ((a > 1) & (a < 4)).select(a, i32x4.splat(0))
    print(f"select {picked[0]} {picked[1]} {picked[2]} {picked[3]} | range {inside[1]} {inside[2]}")

    let s: i32 = 2
    let scaled = s * a
    let u = u32x4(3, 263, 9, 0)
    let masked = 0xff & u
    let shifted = i32x4(60, 4, 0, 0) >> 2
    let f = f32x4(1, 2, 3, 4)
    let positive = (0.0 < f).select(a, i32x4.splat(0))
    print(f"left {scaled[0]} {scaled[1]} {scaled[2]} {scaled[3]} | {masked[0]} {masked[1]} {masked[2]} | {shifted[0]} {shifted[1]} | {positive[0]} {positive[1]} {positive[2]} {positive[3]}")

    let x = Vector[2, i128](1, 5)
    let y = Vector[2, i128](1, 2)
    let e: m128x2 = x == y
    print(f"m128 {e[0]} {e[1]}")
