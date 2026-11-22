//! expect-stdout: ok

// #685: a freed small block joined a freelist and its slab stayed mapped for
// the life of the process, so a program's small-object memory was its
// high-water mark. 200,000 48-byte blocks fill about 200 slabs (13 MB);
// freed, their slabs go back to the system and the committed bytes fall by
// most of that. A second round maps slabs again and works as the first did.
extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut c_void)
extern fn with_alloc_committed_bytes() -> i64

fn round() -> i64:
    let held: List[i64] = []
    unsafe:
        for i in 0..200000:
            let p = with_alloc(48)
            *(p as *mut i64) = i
            held.push(p as i64)
        let peak = with_alloc_committed_bytes()
        var sum: i64 = 0
        for p in held: sum = sum + *(p as *const i64)
        assert(sum == 19999900000)
        for p in held: with_free(p as *mut c_void)
        peak - with_alloc_committed_bytes()

fn main:
    let first = round()
    let second = round()
    assert(first > 8 * 1024 * 1024)
    assert(second > 8 * 1024 * 1024)
    print("ok")
