//! expect-stdout: lanes 1 2 3 4
//! expect-stdout: generic 5 6 7 8
//! expect-stdout: write 1 20 3 40
//! expect-stdout: arith 11 22 33 44 | 9 18 27 36 | 10 40 90 160 | 10 10 10 10 | 1 0 1 0
//! expect-stdout: broadcast 2 4 6 8 | 3 6 9 12 | 7 7 7 7 | 0 0 0 0
//! expect-stdout: splat 9 9 9 9
//! expect-stdout: neg -1 -2 -3 -4
//! expect-stdout: bits 1 7 6 4294967294 | 2 4 6 8 | 0 1 1 2
//! expect-stdout: select 10 20 3 4 | all false any true | all true
//! expect-stdout: reduce 10 24 1 4 0 7 4
//! expect-stdout: swizzle 1 2 | 4 3 2 1 | 1 1 1 1 | 3 1
//! expect-stdout: cast 1 2 3 4 | 1 2 3 4
//! expect-stdout: layout 16 16 32 16 16 64
//! expect-stdout: floats 0 failures
//! expect-stdout: calls 6 8 10 12 | 2 4 6 8 10 12 14 16 | 3 5 7

// §4.3d (D78, #1874): SIMD vectors. `Vector[N, T]` and its one-token
// aliases name the same type; lanes are read and written with `v[i]`;
// operators are lane-wise; a comparison yields a Mask; a scalar broadcasts
// only where one meaning is forced.

fn show4(label: str, v: i32x4): print(f"{label} {v[0]} {v[1]} {v[2]} {v[3]}")

fn lanes4(v: i32x4) -> str: f"{v[0]} {v[1]} {v[2]} {v[3]}"

fn add4(a: f32x4, b: f32x4) -> f32x4: a + b

fn double8(a: i32x8) -> i32x8: a * 2

fn add3(a: Vector[3, i32], b: Vector[3, i32]) -> Vector[3, i32]: a + b

fn near(a: f32, b: f32) -> bool: (a - b).abs() < 0.0001f32

fn main:
    let v = i32x4(1, 2, 3, 4)
    show4("lanes", v)
    let g = Vector[4, i32](5, 6, 7, 8)
    show4("generic", g)

    var w = v
    w[1] = 20
    let k = 3
    w[k] = 40
    show4("write", w)

    let a = i32x4(10, 20, 30, 40)
    let b = i32x4(1, 2, 3, 4)
    print(f"arith {lanes4(a + b)} | {lanes4(a - b)} | {lanes4(a * b)} | {lanes4(a / b)} | {lanes4(i32x4(1, 2, 3, 4) % i32x4(2, 2, 2, 2))}")

    let s = 3
    let z: i32x4 = 0
    let seven: i32x4 = 7
    print(f"broadcast {lanes4(b * 2)} | {lanes4(b * s)} | {lanes4(seven)} | {lanes4(z)}")
    print(f"splat {lanes4(i32x4.splat(9))}")
    print(f"neg {lanes4(-b)}")

    let u = u32x4(3, 5, 6, 1)
    let m = u32x4(1, 3, 7, 4)
    let and_ = u & m
    let or_ = u | m
    let xor_ = u ^ m
    let not_ = ~u
    let shl = b << 1
    let shr = b >> 1
    print(f"bits {and_[0]} {or_[1]} {xor_[3] + 1} {not_[3]} | {lanes4(shl)} | {lanes4(shr)}")

    let lt: m32x4 = a > i32x4(15, 25, 25, 45)
    let picked = lt.select(b, a)
    let eq_all = a == a
    print(f"select {lanes4((a < 25).select(a, b))} | all {lt.all()} any {lt.any()} | all {eq_all.all()}")
    let _ = picked

    let r = i32x4(1, 2, 3, 4)
    let flags = u32x4(1, 2, 4, 0)
    print(f"reduce {r.reduce_add()} {r.reduce_mul()} {r.reduce_min()} {r.reduce_max()} {flags.reduce_and()} {flags.reduce_or()} {flags.reduce_xor() - 3}")

    let xy = v.xy
    let rev = v.wzyx
    let xxxx = v.xxxx
    print(f"swizzle {xy[0]} {xy[1]} | {lanes4(rev)} | {lanes4(xxxx)} | {v.z} {v.x}")

    let f = f32x4(1.5, 2.5, 3.5, 4.5)
    let fi = f as i32x4
    let back = fi as f32x4
    let wide = i64x4(1, 2, 3, 4)
    let narrow = wide as i32x4
    print(f"cast {lanes4(fi)} | {lanes4(narrow)}")
    let _ = back

    print(f"layout {size_of[Vector[3, f32]]()} {align_of[Vector[3, f32]]()} {size_of[f32x8]()} {size_of[m32x4]()} {align_of[i8x16]()} {size_of[Vector[5, f64]]()}")

    var fails = 0
    let fa = f32x4(1, 2, 3, 4)
    let fb = fa * 0.5
    if not near(fb[1], 1.0f32): fails += 1
    let fz: f32x4 = 0
    if not near(fz[3], 0.0f32): fails += 1
    let sc = 2.0f32
    let fc = fa * sc + 1
    if not near(fc[2], 7.0f32): fails += 1
    let raw = fa.bits()
    if raw[0] != 1065353216u32: fails += 1
    let again = f32x4.from_bits(raw)
    if not near(again[3], 4.0f32): fails += 1
    if not near(add4(fa, fa)[2], 6.0f32): fails += 1
    if not near(fa.reduce_add(), 10.0f32): fails += 1
    if not near(fa.reduce_max(), 4.0f32): fails += 1
    let fm = fa >= 2.5
    if fm.any() == false: fails += 1
    print(f"floats {fails} failures")

    let d = double8(i32x8(1, 2, 3, 4, 5, 6, 7, 8))
    let t = add3(Vector[3, i32](1, 2, 3), Vector[3, i32](2, 3, 4))
    print(f"calls {lanes4(i32x4(1, 2, 3, 4) + i32x4(5, 6, 7, 8))} | {d[0]} {d[1]} {d[2]} {d[3]} {d[4]} {d[5]} {d[6]} {d[7]} | {t[0]} {t[1]} {t[2]}")
