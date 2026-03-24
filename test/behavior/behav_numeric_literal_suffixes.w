//! expect-stdout: ok

fn take_u64(v: u64) -> u64:
    v

type Pair {
    x: f64,
    y: f64,
}

fn ret_u64() -> u64:
    0

fn main:
    var acc: u64 = 0
    let a = 255u8
    let b = 0xFFu32
    let c = 1.5f32
    let mask: u32 = 0xFF
    let x = take_u64(42)
    let y = acc + 1
    let z = acc >> 31
    let p = Pair { x: 0, y: 0 }
    let arr: [u8; 4] = [0, 1, 2, 3]
    assert(a == 255u8)
    assert(b == 255u32)
    assert(c > 1.0f32)
    assert(mask == 255u32)
    assert(x == 42u64)
    assert(y == 1u64)
    assert(z == 0u64)
    assert(ret_u64() == 0u64)
    assert(p.x == 0.0)
    assert(arr[3] == 3u8)
    println("ok")
