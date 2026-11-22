unsafe fn read_cast(p: *const u8) -> u32:
    *(p + 0 as u64) as u32

unsafe fn read_cast_local(p: *const u8) -> u32:
    let v = *(p + 0 as u64) as u32
    v

fn main:
    let data = [7 as u8]
    let p = (&data[0]) as *const u8
    let a = unsafe { read_cast(p) }
    let b = unsafe { read_cast_local(p) }
    assert(a == 7 as u32)
    assert(b == 7 as u32)
