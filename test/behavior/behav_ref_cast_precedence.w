//! expect-stdout: ok

fn test_mut_ref_cast_chain:
    var buf: [4]u8 = [0 as u8; 4]
    let p = &raw mut buf as *mut [4]u8 as *mut u8
    unsafe *p = 65 as u8
    unsafe *((p as i64 + 1) as *mut u8) = 66 as u8
    assert(buf[0] == 65 as u8)
    assert(buf[1] == 66 as u8)

fn test_shared_ref_cast_chain:
    var buf: [4]u8 = [0 as u8; 4]
    let p = &raw mut buf as *mut [4]u8 as *mut u8
    unsafe *p = 67 as u8
    unsafe *((p as i64 + 1) as *mut u8) = 68 as u8

    let q = &buf as *const [4]u8 as *const u8
    assert(unsafe *q == 67 as u8)
    assert(unsafe *((q as i64 + 1) as *const u8) == 68 as u8)

fn main:
    test_mut_ref_cast_chain()
    test_shared_ref_cast_chain()
    print("ok")
