//! expect-stdout: true
//! expect-stdout: false

// #1882: with a signature identical to the bundle's private
// `u128_mul_would_overflow(a: u128, b: u128) -> bool` (lib/std/re/defs.w),
// Sema saw no mismatch and the two bodies shared one symbol: "invalid MIR
// before codegen: body index map mismatch for fn symbol N". Each owner's
// definition is its own; the importer calls the header's.
use c_import("static inline _Bool u128_mul_would_overflow(unsigned __int128 a, unsigned __int128 b) { return a == 7 && b == 9; }\n")

fn main:
    print(f"{u128_mul_would_overflow(7u128, 9u128)}")
    print(f"{u128_mul_would_overflow(1u128, 2u128)}")
