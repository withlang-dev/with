//! expect-stdout: 18446744073709551615 4294967295 -1

// #1773 / #1820: arithmetic of unsuffixed literals alone has the global's
// declared type (§4.2.1 rule 1 reaches through the operators), as limits.h's
// ULONG_LONG_MAX (`__LONG_LONG_MAX__*2ULL+1ULL`) does through c_import:
// typed with the literal default i64, the fold refused and the startup
// initializer panicked.
let ULL_MAX: u64 = (9223372036854775807 * 2 + 1)
let U_MAX: u32 = 2147483647 * 2 + 1
let NEG: i16 = -(2 - 3) * -1

fn main:
    print(f"{ULL_MAX} {U_MAX} {NEG}")
