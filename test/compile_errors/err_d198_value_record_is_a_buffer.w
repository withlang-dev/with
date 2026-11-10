//! expect-check-fail: a pointer paired with a count is a buffer (§16.2b.8), not a value record
// D198 (§16.2b.5): a pointer paired with a count is a buffer, whichever clause comes first.
use c_import("typedef struct { int w; int h; } Size; static inline int total(const Size *sizes, int count) { int t = 0; for (int i = 0; i < count; i++) t += sizes[i].w; return t; }")

c facade shapes:
    fn total
        reads param sizes
        buffer param sizes len param count elements

fn main:
    print("unreachable")
