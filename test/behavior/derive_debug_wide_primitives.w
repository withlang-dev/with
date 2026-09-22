//! expect-stdout: P { x: 1.5, y: 4294967295, z: 18446744073709551615, w: -3, v: 2.5, u: -9, t: 65535 }
//! expect-stdout: 1.5

// #1288: §11.8 derives Debug unconditionally, so every primitive a field
// can hold has a Debug impl (f32/f64, i8/i16, u16/u32/u64); the derive
// used to fail with "unknown method 'debug_str' for type 'f64'". The
// derived debug_str observes (`&Self`, as the trait declares): p is whole
// after the call.

@[derive(Debug)]
type P { x: f64, y: u32, z: u64, w: i8, v: f32, u: i16, t: u16 }

fn main:
    let p = P { x: 1.5, y: 4294967295, z: 18446744073709551615, w: -3, v: 2.5, u: -9, t: 65535 }
    print(p.debug_str())
    print(f"{p.x}")
