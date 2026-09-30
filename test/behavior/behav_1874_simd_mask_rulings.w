//! expect-stdout: write false true false true | true
//! expect-stdout: literal true false
//! expect-stdout: select 7 2 3 4 | 1 20 3 40 | 5 0 0 0

// §4.3d (v7.16, the D80 amendment): `m[i] = b` writes a mask lane; a
// `bool` literal in a mask context broadcasts; a scalar `a` or `b` of
// `m.select(a, b)` broadcasts beside a vector operand or where the context
// gives the vector type.
fn main:
    var m = m32x4.splat(false)
    m[1] = true
    let k = 3
    m[k] = true
    var flip = m32x4(false, false, false, false)
    flip[0] = not flip[0]
    print(f"write {m[0]} {m[1]} {m[2]} {m[3]} | {flip[0]}")

    let on: m32x4 = true
    let off: Mask[4, 8] = false
    print(f"literal {on.all()} {off.any()}")

    let v = i32x4(1, 2, 3, 4)
    let odd = (v < 3) & m32x4(true, false, true, false)
    let s = 7
    let left = odd.select(s, v)
    let right = m.select(v * 10, v)
    let both: i32x4 = odd.select(5, 0)
    print(f"select {left[0]} {left[1]} {left[2]} {left[3]} | {right[0]} {right[1]} {right[2]} {right[3]} | {both[0]} {both[1]} {both[2]} {both[3]}")
