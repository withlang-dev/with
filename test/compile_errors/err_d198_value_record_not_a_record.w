//! expect-check-fail: a value record is a pointer to one complete record; this is not one (§16.2b.5)
//! expect-check-fail: = help: a pointer with a count is 'buffer param P len param L'; text is 'text param P'; an opaque record is a resource ('resource Name wraps *mut T')
// D198 (§16.2b.5): a value-record clause names a pointer to one complete record.
use c_import("static inline int twice(const int *n) { return *n * 2; }")

c contract shapes:
    fn twice
        reads param n

fn main:
    print("unreachable")
