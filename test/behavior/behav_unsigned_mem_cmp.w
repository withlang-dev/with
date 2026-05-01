//! expect-stdout: ok

// Regression test for #160: u32 comparisons from memory loads must use
// unsigned comparison (icmp ult), not signed (icmp slt).
// Values above 0x7FFFFFFF trigger the bug because they are negative
// when interpreted as signed i32.

extern fn getpid() -> i32

fn opaque_u32(v: u32) -> u32:
    v + ((getpid() * 0) as u32)

fn test_u32_local_cmp:
    let a: u32 = opaque_u32(97)
    let b: u32 = opaque_u32(2147483648)
    assert(a < b)
    assert(b > a)
    assert(a <= b)
    assert(b >= a)

fn test_u32_deref_cmp:
    var buf: [2]u32
    (buf[0] = opaque_u32(97))
    (buf[1] = opaque_u32(2147483648))
    let p = (&raw mut buf[0] as *mut u32)
    let q = (&raw mut buf[1] as *mut u32)
    assert((unsafe: *p) < (unsafe: *q))
    assert((unsafe: *q) > (unsafe: *p))
    assert((unsafe: *p) <= (unsafe: *q))
    assert((unsafe: *q) >= (unsafe: *p))

fn test_u32_array_cmp:
    var arr: [2]u32
    (arr[0] = opaque_u32(97))
    (arr[1] = opaque_u32(2147483648))
    assert(arr[0] < arr[1])
    assert(arr[1] > arr[0])
    assert(arr[0] <= arr[1])
    assert(arr[1] >= arr[0])

fn test_u32_mixed_cmp:
    let local: u32 = opaque_u32(97)
    var arr: [1]u32
    (arr[0] = opaque_u32(2147483648))
    assert(local < arr[0])
    assert(arr[0] > local)

fn test_u32_boundary:
    var arr: [2]u32
    (arr[0] = opaque_u32(2147483647))
    (arr[1] = opaque_u32(2147483648))
    assert(arr[0] < arr[1])
    assert(arr[1] > arr[0])

fn test_u32_max:
    var arr: [2]u32
    (arr[0] = opaque_u32(2147483648))
    (arr[1] = opaque_u32(4294967295))
    assert(arr[0] < arr[1])
    assert(arr[1] > arr[0])

fn main:
    test_u32_local_cmp()
    test_u32_deref_cmp()
    test_u32_array_cmp()
    test_u32_mixed_cmp()
    test_u32_boundary()
    test_u32_max()
    print("ok")
