//! expect-check-fail: a pointer paired with a count is a buffer (§16.2b.8), not a value record
//! expect-check-fail: = help: delete the `reads`/`fills`/`updates` clause and keep 'buffer param P len param L'

// #3129: one parameter has one contract: a buffer, or a value record.
use c_import("typedef struct rec { int a; } rec;\nint put(const rec *p, unsigned long n);\n")

c contract lib:
    fn put
        reads param p
        buffer param p len param n elements

fn main:
    print("unreachable")
