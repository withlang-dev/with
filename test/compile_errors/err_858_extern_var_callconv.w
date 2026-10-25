//! expect-check-fail: an extern var takes @[link_name("symbol")] only
// #858: the other callconv-carried attributes are a function's; on an extern
// var they were dropped without a word.
@[callconv("c")]
extern var process_environment: *mut *mut u8

fn main:
    print(process_environment != null)
