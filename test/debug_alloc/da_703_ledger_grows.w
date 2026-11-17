//! expect-debug-alloc: size=64 origin=with_alloc first_drop=<untagged> second_drop=<untagged>
// #703: the ledger doubles when it is half full, and every entry moves with
// its history. `first` is recorded while the table has 65,536 slots; the
// 200,000 blocks held beside it grow the table three times. Freed twice
// afterwards, `first` is still found, and the double free states its size
// and origin, which only the moved entry holds. (Every platform prints that
// line; the first free's calling chain, Darwin's, is da_1014's.)
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
