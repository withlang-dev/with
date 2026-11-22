//! expect-stdout: 3.7
//! expect-stdout: 12
//! expect-stdout: 5.5
//! expect-stdout: 7.25
//! expect-stdout: true
//! expect-stdout: 2.5
//! expect-stdout: inf
//! expect-stdout: ok

// D182 (§4.2.6): a float where a narrower float is demanded converts to
// it, rounding to nearest (the `as` conversion); a float beside a wider
// float is the wider float. Float-to-integer stays explicit (D181).

type V2:
    x: f32
    y: f32

fn takes_f32(v: f32) -> f32: v

fn half(v: f64) -> f32: v / 2.0

const WIDE: f64 = 12.0

fn main:
    let f: f64 = 3.7
    let g: f32 = f
    print(f"{g}")
    let z: f32 = WIDE
    print(f"{z}")
    print(f"{takes_f32(5.5)}")
    let v = V2 { x: 1.25, y: 2.0 }
    let w = V2 { x: v.x + 6.0 * 1.0, y: half(v.y) }
    print(f"{w.x}")
    let big: f64 = 1.0e300
    let h: f32 = big
    print(f"{v.x + 1.25 == 2.5}")
    print(f"{half(5.0)}")
    print(f"{h}")
    print("ok")
