//! expect-check-fail: which is not a pointer to bytes
//! expect-check-fail: = help: for a count of elements write 'buffer param 0 len param 1 elements'; a pointer to one record is `reads`, `fills` or `updates`

// D64 §16.2b.8: the length counts bytes, so the buffer parameter points at
// bytes; a pointer to another element type is refused rather than rendered
// as a `[]u8` over ints.
use c_import("static inline int sum_ints(const int *p, unsigned long n) { if (n > 0) return p[0]; return 0; }\n")

c contract sums:
    fn sum_ints
        buffer param p len param n

fn main:
    print("unreachable")
