//! expect-check-fail: a value record is a pointer to one complete record; this is not one (§16.2b.5)
// D198 (§16.2b.5): a value-record clause names a pointer to one complete record.
use c_import("static inline int twice(const int *n) { return *n * 2; }")

c contract shapes:
    fn twice
        reads param n

fn main:
    print("unreachable")
