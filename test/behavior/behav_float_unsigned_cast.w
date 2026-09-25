//! expect-stdout: ok

// Obtain values at runtime: constant folding of out-of-range fptosi poison
// can erase the assertion and make the wrong lowering appear to pass.
extern fn strtod(text: *const u8, end: *mut *mut u8) -> f64

fn convert64(x: f64) -> u64: x as u64
fn convert32(x: f64) -> u32: x as u32
fn convert16(x: f64) -> u16: x as u16
fn convert8(x: f64) -> u8: x as u8
fn convert32f(x: f32) -> u32: x as u32
fn convert64f(x: f32) -> u64: x as u64
fn signed64(x: f64) -> i64: x as i64

fn main:
    let high = unsafe { strtod(c"10000000000000000000".ptr, 0 as *mut *mut u8) }
    assert(convert64(high) == 10000000000000000000u64)
    let wide = unsafe { strtod(c"4000000000".ptr, 0 as *mut *mut u8) }
    assert(convert32(wide) == 4000000000u32)
    assert(convert32f(wide as f32) == 4000000000u32)
    let half = unsafe { strtod(c"9223372036854775808".ptr, 0 as *mut *mut u8) }
    assert(convert64f(half as f32) == 9223372036854775808u64)
    let medium = unsafe { strtod(c"60000".ptr, 0 as *mut *mut u8) }
    assert(convert16(medium) == 60000u16)
    let small = unsafe { strtod(c"250".ptr, 0 as *mut *mut u8) }
    assert(convert8(small) == 250u8)
    assert(signed64(-small) == -250)
    print("ok")
