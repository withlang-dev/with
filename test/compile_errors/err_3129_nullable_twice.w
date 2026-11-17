//! expect-check-fail: 'nullable param 0' is stated twice
//! expect-check-fail: = help: delete one of the two 'nullable' clauses

// #3129 (§16.2b.8): one parameter has one `nullable` clause.
use c_import("static inline int count(const char *s) { return 0; }\n")

c contract counts:
    fn count
        nullable param s
        nullable param s

fn main:
    print("unreachable")
