//! expect-check-fail: 'param 0 fixed' binds a boolean to param 0: i32 a, which is not a bool
//! expect-check-fail: = help: fix an integer with its literal ('param 0 fixed 1'), a pointer with 'null'

// #3129 (§16.2b.11): the refusal of a boolean fixed to an integer parameter
// states the accepted spelling.
use c_import("static inline int add3(int a, int b) { return a + b; }\n")

c contract adds:
    fn add3
        param a fixed true

fn main:
    print("unreachable")
