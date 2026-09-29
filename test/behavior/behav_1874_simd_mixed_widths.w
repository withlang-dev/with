//! expect-stdout: wide 5000000001 7 true
//! expect-stdout: float 2.5 true
//! expect-stdout: cmp true

// §4.3d (D78, #1874): operators follow §4.2 per lane, so lanes of one
// signedness widen losslessly (§4.2.4 rule 2, §4.2.6): i32x4 + i64x4 is
// i64x4 and f32x4 * f64x4 is f64x4; a comparison's mask has the wider lane.
fn main:
    let a = i32x4(1, 2, 3, 4)
    let b = i64x4(5000000000, 5, 6, 7)
    let s = a + b
    let s_is_i64x4: i64x4 = s
    print(f"wide {s_is_i64x4[0]} {s[1]} {(b + a)[3] == 11}")
    let f = f32x4(0.5, 1, 2, 3)
    let d = f64x4(5, 1, 1, 1)
    let p: f64x4 = f * d
    print(f"float {p[0]} {p[3] == 3.0}")
    let m: m64x4 = a < b
    print(f"cmp {m.all()}")
