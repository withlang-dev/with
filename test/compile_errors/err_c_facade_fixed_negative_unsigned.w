//! expect-check-fail: binds a negative literal to param 1: u32 b, an unsigned integer

// D64 §16.2b.11: a negative literal is not a value of an unsigned parameter.
use c_import("static inline int addu(int a, unsigned int b) { return a + (int)b; }\n")

c facade adds:
    fn addu
        param b fixed -1

fn main:
    print("unreachable")
