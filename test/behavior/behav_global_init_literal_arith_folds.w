//! expect-stdout: 18446744073709551615 4294967295 -1

// #1773: arithmetic of unsuffixed literals alone takes the global's
// declared type when folded, as limits.h's ULONG_LONG_MAX does through
// c_import (`__LONG_LONG_MAX__*2ULL+1ULL`): recording the literal-default
// i64 for it made the fold refuse and the startup initializer panic.
let ULL_MAX: u64 = (9223372036854775807 * 2 + 1)
let U_MAX: u32 = 2147483647 * 2 + 1
let NEG: i16 = -(2 - 3) * -1

fn main:
    print(f"{ULL_MAX} {U_MAX} {NEG}")
