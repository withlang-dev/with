//! expect-check-fail: 'text param 0' is stated twice
//! expect-check-fail: = help: delete one of the two 'text param' clauses

// #3129 (§16.2b.8): one parameter has one `text param` clause.
use c_import("static inline int count(const char *s) { return 0; }\n")

c contract counts:
    fn count
        text param s
        text param s

fn main:
    print("unreachable")
