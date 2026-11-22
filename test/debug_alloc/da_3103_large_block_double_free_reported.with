//! expect-debug-alloc: DOUBLE FREE
// #3103: a freed large block (over 4 KiB) is kept mapped for reuse, its size
// word 0. A str naming it is still a double free for the ledger: the block
// is recorded but not an owned payload, so the second free reaches the
// debug allocator's report, as a small block's does.
extern fn with_str_free(s: *mut u8)
fn main:
    var text = ""
    for i in 0..600: text = text ++ "a large payload line\n"
    let s = text ++ ""
    unsafe:
        var alias = ""
        *(&raw mut alias as *mut [2]i64) = *(&raw const s as *const [2]i64)
        with_str_free(&raw mut alias as *mut u8)
