//! expect-stdout: ok

type RawFn0I32 {
    fn_ptr: *mut u8,
    ctx: *mut u8,
}

type Fn0I32 = fn() -> i32

fn main:
    let signed: i32 = -1
    let bits: u32 = unsafe { transmute[u32](signed) }
    assert(bits == 4294967295u32)

    let back: i32 = unsafe { transmute[i32](bits) }
    assert(back == -1)

    let wide_bits: u64 = unsafe { transmute[u64](-1 as i64) }
    assert(wide_bits == 18446744073709551615u64)

    assert(sizeof[Fn0I32]() == sizeof[RawFn0I32]())
    let worker: Fn0I32 = () => 42
    let raw: RawFn0I32 = unsafe { transmute[RawFn0I32](worker) }
    assert(raw.fn_ptr != null)

    print("ok")
