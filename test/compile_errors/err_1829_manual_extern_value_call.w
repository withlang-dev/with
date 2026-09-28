//! expect-error: call to unsafe function pointer requires unsafe context

// §16.3, §16.11 (#1829): a manual extern whose call needs `unsafe` (a raw
// pointer parameter) is an unsafe callable as a value too.

extern "C" fn strlen(s: *const u8) -> usize

fn main:
    let f = strlen
    print(f(c"abc".ptr as *const u8))
