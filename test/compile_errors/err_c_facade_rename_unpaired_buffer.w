//! expect-check-fail: is a raw pointer that no clause pairs, so it is not a buffer; a presented operation renders no call without a bounds contract

// D64 §16.2b.8: a raw pointer parameter that no clause pairs is not a
// buffer, and a presentation clause on such a function — here a `rename`
// with no `lend` (the `lend` case is err_c_facade_lend_unpaired_buffer) —
// is refused, naming the parameter and the clauses that would pair or
// bind it.
use c_import("static inline int compress2(unsigned char *dest, unsigned long *destLen, const unsigned char *source, unsigned long sourceLen) { *destLen = 0; return 0; }\n")

c facade z:
    fn compress2
        rename pack

fn main:
    print("unreachable")
