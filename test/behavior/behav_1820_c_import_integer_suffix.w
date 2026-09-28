//! skip-on: windows #799: `use c_import("limits.h")` does not yet compile as a C header snippet on native Windows (UCRT/MSVC header modeling, task #79)
//! expect-stdout: 18446744073709551615 4294967295 4294967295
//! expect-stdout: 6

// #1820: c_import keeps a C integer literal's suffix (C11 6.4.4.1), so
// limits.h's `__LONG_LONG_MAX__*2ULL+1ULL` is u64 arithmetic on its own,
// and a header's `2ULL * 3ULL` is u64 wherever it is used.
use c_import("limits.h")
use c_import("#define WITH_1820_PRODUCT (2ULL * 3ULL)\n#define WITH_1820_UMAX (0xffffffffu)\n")

fn main:
    let ull: u64 = ULLONG_MAX
    let uint: u32 = UINT_MAX
    print(f"{ull} {uint} {WITH_1820_UMAX}")
    let p: u64 = WITH_1820_PRODUCT
    print(f"{p}")
