//! expect-check-fail: a pointer paired with a count is a buffer
//! expect-check-fail: = help: delete the

// #3129 (§16.2b.5, §16.2b.8): a pointer with a count is a buffer, not a value record.
use c_import("typedef struct pt { int x; int y; } pt;\nstatic inline int sum(const pt *ps, unsigned long n) { return 0; }\n")

c contract pts:
    fn sum
        buffer param ps len param n elements
        reads param ps

fn main:
    print("unreachable")
