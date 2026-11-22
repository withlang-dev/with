//! expect-stdout: 18446744073709551615
//! expect-stdout: 9223372036854775808
//! expect-stdout: 9223372032559808512
//! expect-stdout: 18446744073709551615
//! expect-stdout: 1

// #1911: an imported macro whose operands differ in signedness computes in
// C's common type: `LLONG_MAX * 2ULL + 1` is unsigned long long arithmetic,
// not an i64 multiplication that overflows (or a refused sign change).
use c_import("behav_c_import_macro_usual_conversions.h")
fn main:
    print(W1911_ULLONG_MAX())
    print(W1911_UNSIGNED_WINS())
    print(W1911_SIGNED_WIDER())
    print(W1911_BITWISE())
    print(W1911_COMPARED())
