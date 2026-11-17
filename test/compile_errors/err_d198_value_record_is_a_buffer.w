//! expect-check-fail: a pointer paired with a count is a buffer (§16.2b.8), not a value record
//! expect-check-fail: = help: delete the `reads`/`fills`/`updates` clause and keep 'buffer param P len param L'
// D198 (§16.2b.5): a pointer paired with a count is a buffer, whichever clause comes first.
use c_import("typedef struct { int w; int h; } Size; static inline int total(const Size *sizes, int count) { int t = 0; for (int i = 0; i < count; i++) t += sizes[i].w; return t; }")

c contract shapes:
    fn total
        reads param sizes
        buffer param sizes len param count elements

fn main:
    print("unreachable")
