//! only-on: darwin
//! expect-debug-alloc: debug-alloc: first free (innermost first
// #703: the ledger doubles when it is half full, and every entry moves with
// its history. `first` is recorded while the table has 65,536 slots; the
// 200,000 blocks held beside it grow the table three times. Freed twice
// afterwards, `first` is still found: the double free names the first
// free's chain, which the moved entry carries.
extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut c_void)
fn main:
    unsafe:
        let first = with_alloc(64)
        let held: List[i64] = []
        for i in 0..200000: held.push(with_alloc(48) as i64)
        for p in held: with_free(p as *mut c_void)
        with_free(first)
        with_free(first)
